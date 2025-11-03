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

    init(settings: AppSettings = .shared) {
        self.settings = settings
        self._viewModel = StateObject(wrappedValue: TripsViewModel(
            context: PersistenceController.shared.container.viewContext,
            settings: settings
        ))
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
            .alert("Fehler", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
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
            .onChange(of: deepLinkHandler.pendingAction) { _, newAction in
                guard let action = newAction else { return }

                Task {
                    switch action {
                    case .startTrip:
                        await viewModel.startTrip()
                        if viewModel.activeTrip != nil {
                            showingActiveTripView = true
                        }

                    case .endTrip:
                        await viewModel.endTrip()
                    }

                    // Action als verarbeitet markieren
                    deepLinkHandler.clearPendingAction()
                }
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

                    Text(trip.durationFormatted)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green.opacity(0.2), in: Capsule())
                        .foregroundStyle(.green)
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
                // Monats-Header mit Summary
                let summary = viewModel.monthlySummary(for: group.trips)
                MonthSectionHeader(monthString: group.monthString, summary: summary) {
                    exportMonth(trips: group.trips, summary: summary)
                }

                // Fahrten
                ForEach(group.trips) { trip in
                    TripRowView(
                        trip: trip,
                        settings: settings
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.deleteTrip(trip)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
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
}

#Preview {
    TripsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(DeepLinkHandler.shared)
}
