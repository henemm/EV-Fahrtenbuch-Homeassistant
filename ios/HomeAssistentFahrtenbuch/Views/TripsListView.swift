//
//  TripsListView.swift
//  HomeAssistent Fahrtenbuch
//
//  Hauptscreen: Fahrten-Liste mit "Fahrt starten" Button
//

import SwiftUI
import CoreData

struct TripsListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @StateObject private var viewModel: TripsViewModel
    @ObservedObject private var settings: AppSettings

    @FetchRequest(
        fetchRequest: PersistenceController.fetchCompletedTrips(),
        animation: .smooth
    )
    private var trips: FetchedResults<Trip>

    @State private var showingActiveTripView = false
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showingDeepLinkAlert = false
    @State private var deepLinkAlertConfig: DeepLinkAlertConfig?

    // Edit/Create Trip
    @State private var showingEditTrip = false
    @State private var tripToEdit: Trip?

    // Offline-Modus
    @State private var manualBatteryInput = ""

    // Collapsible Sections
    @State private var expandedMonths: Set<String> = []

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self._viewModel = StateObject(wrappedValue: TripsViewModel(
            context: PersistenceController.shared.container.viewContext,
            settings: settings
        ))

        // Initial: Aktueller Monat expanded
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        let currentMonth = formatter.string(from: Date())
        self._expandedMonths = State(initialValue: [currentMonth])
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // Start-Button oder Active Trip Hinweis
                        if let activeTrip = viewModel.activeTrip {
                            activeTripCard(activeTrip)
                        } else {
                            startTripButton
                        }

                        // Fahrten gruppiert nach Monat
                        if trips.isEmpty {
                            emptyStateView
                        } else {
                            tripsListByMonth
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("🚗 Fahrtenbuch")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        tripToEdit = nil
                        showingEditTrip = true
                    } label: {
                        Label("Fahrt erstellen", systemImage: "plus")
                    }
                }
            }
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .alert("Keine Verbindung", isPresented: $viewModel.showManualInputAlert) {
                TextField("Batterie %", text: $manualBatteryInput)
                    .keyboardType(.decimalPad)

                Button("Abbrechen", role: .cancel) {
                    manualBatteryInput = ""
                }

                Button(viewModel.manualInputContext == .startTrip ? "Fahrt starten" : "Fahrt beenden") {
                    guard let battery = Double(manualBatteryInput),
                          battery >= 0 && battery <= 100 else {
                        // Validation fehlgeschlagen
                        viewModel.errorMessage = "Batterie muss zwischen 0 und 100% sein"
                        manualBatteryInput = ""
                        return
                    }

                    if viewModel.manualInputContext == .startTrip {
                        viewModel.startTripManually(batteryPercent: battery)
                    } else {
                        viewModel.endTripManually(batteryPercent: battery)
                    }

                    manualBatteryInput = ""
                }
                .disabled(manualBatteryInput.isEmpty)
            } message: {
                Text("Bitte gib den aktuellen Batteriestand ein:")
            }
            .sheet(isPresented: $showingActiveTripView) {
                if let activeTrip = viewModel.activeTrip {
                    ActiveTripView(trip: activeTrip, viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if !shareItems.isEmpty {
                    ActivityViewController(activityItems: shareItems)
                }
            }
            .sheet(isPresented: $showingEditTrip) {
                EditTripView(viewModel: viewModel, trip: tripToEdit)
            }
            .onChange(of: deepLinkHandler.pendingAction) { _, newAction in
                guard let action = newAction else { return }

                // Bestimme Alert-Konfiguration basierend auf Action + Zustand
                switch action {
                case .startTrip:
                    if viewModel.activeTrip != nil {
                        // Fahrt läuft bereits
                        deepLinkAlertConfig = DeepLinkAlertConfig(
                            title: "Fahrt läuft bereits",
                            message: "Eine Fahrt ist bereits aktiv. Möchtest du sie beenden und eine neue starten?",
                            confirmTitle: "Beenden & Neu starten",
                            action: {
                                Task {
                                    await viewModel.endTrip()
                                    await viewModel.startTrip()
                                    if viewModel.activeTrip != nil {
                                        showingActiveTripView = true
                                    }
                                }
                            }
                        )
                    } else {
                        // Keine Fahrt läuft
                        deepLinkAlertConfig = DeepLinkAlertConfig(
                            title: "Neue Fahrt starten",
                            message: "Möchtest du eine neue Fahrt protokollieren?",
                            confirmTitle: "Starten",
                            action: {
                                Task {
                                    await viewModel.startTrip()
                                    if viewModel.activeTrip != nil {
                                        showingActiveTripView = true
                                    }
                                }
                            }
                        )
                    }
                    showingDeepLinkAlert = true

                case .endTrip:
                    if viewModel.activeTrip != nil {
                        // Fahrt läuft → Alert zeigen
                        deepLinkAlertConfig = DeepLinkAlertConfig(
                            title: "Fahrt beenden",
                            message: "Möchtest du die laufende Fahrt beenden?",
                            confirmTitle: "Beenden",
                            action: {
                                Task {
                                    await viewModel.endTrip()
                                }
                            }
                        )
                        showingDeepLinkAlert = true
                    }
                    // Keine Fahrt läuft → nichts tun (silent)
                }

                // Action als verarbeitet markieren
                deepLinkHandler.clearPendingAction()
            }
            .alert(
                deepLinkAlertConfig?.title ?? "",
                isPresented: $showingDeepLinkAlert,
                presenting: deepLinkAlertConfig
            ) { config in
                Button(config.confirmTitle, role: .none) {
                    config.action()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: { config in
                Text(config.message)
            }
        }
    }

    // MARK: - Export

    private func exportMonth(trips: [Trip], summary: TripsViewModel.MonthlySummary?) {
        guard let summary = summary else { return }

        let exportService = ExportService.shared

        // Erstelle beide Dateien
        if let reportURL = exportService.createReportFile(for: trips, settings: settings, summary: summary),
           let csvURL = exportService.createCSVFile(for: trips, settings: settings) {
            shareItems = [reportURL, csvURL]
            showingShareSheet = true
        }
    }

    // MARK: - Start Trip Button

    private var startTripButton: some View {
        Button {
            Task {
                await viewModel.startTrip()
                if viewModel.activeTrip != nil {
                    showingActiveTripView = true
                }
            }
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)

                Text("Fahrt starten")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green.gradient, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
            .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(viewModel.isLoading || !settings.isConfigured)
        .opacity(viewModel.isLoading ? 0.6 : 1.0)
        .sensoryFeedback(.impact, trigger: viewModel.activeTrip)
    }

    // MARK: - Active Trip Card

    private func activeTripCard(_ trip: Trip) -> some View {
        Button {
            showingActiveTripView = true
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Fahrt läuft...")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("Start: \(trip.startDateFormatted)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let startDate = trip.startDate {
                        Text(startDate, style: .timer)
                            .font(.caption)
                            .monospacedDigit()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 16) {
                    Label("\(Int(trip.startBatteryPercent))%", systemImage: "bolt.fill")
                        .font(.subheadline)

                    Label("\(Int(trip.startOdometer)) km", systemImage: "road.lanes")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.green, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trips List by Month

    private var tripsListByMonth: some View {
        ForEach(groupedTripsByMonth(), id: \.month) { group in
            VStack(spacing: 12) {
                // Monats-Header mit Summary (tappable für Expand/Collapse)
                let summary = viewModel.monthlySummary(for: group.trips)
                let isExpanded = expandedMonths.contains(group.monthString)

                Button {
                    withAnimation(.smooth) {
                        if isExpanded {
                            expandedMonths.remove(group.monthString)
                        } else {
                            expandedMonths.insert(group.monthString)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        MonthSectionHeader(monthString: group.monthString, summary: summary) {
                            exportMonth(trips: group.trips, summary: summary)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Fahrten (nur wenn expanded)
                if isExpanded {
                    ForEach(group.trips, id: \.id) { trip in
                        TripRowView(
                            trip: trip,
                            settings: settings
                        )
                        .onTapGesture {
                            tripToEdit = trip
                            showingEditTrip = true
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteTrip(trip)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                tripToEdit = trip
                                showingEditTrip = true
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                tripToEdit = trip
                                showingEditTrip = true
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                viewModel.deleteTrip(trip)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Noch keine Fahrten")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Starte deine erste Fahrt mit dem Button oben")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    // MARK: - Helpers

    struct TripsByMonth {
        let month: Date
        let monthString: String
        let trips: [Trip]
    }

    private func groupedTripsByMonth() -> [TripsByMonth] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: trips) { trip in
            calendar.dateComponents([.year, .month], from: trip.startDate ?? Date())
        }

        return grouped.map { components, trips in
            let date = calendar.date(from: components) ?? Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "de_DE")

            return TripsByMonth(
                month: date,
                monthString: formatter.string(from: date),
                trips: trips.sorted { ($0.startDate ?? Date()) > ($1.startDate ?? Date()) }
            )
        }
        .sorted { $0.month > $1.month }
    }

    // MARK: - Deep Link Alert Config

    struct DeepLinkAlertConfig {
        let title: String
        let message: String
        let confirmTitle: String
        let action: () -> Void
    }
}

#Preview {
    TripsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(DeepLinkHandler.shared)
}
