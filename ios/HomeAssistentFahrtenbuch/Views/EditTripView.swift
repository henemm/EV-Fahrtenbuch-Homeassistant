//
//  EditTripView.swift
//  HomeAssistent Fahrtenbuch
//
//  Sheet zum Bearbeiten oder Erstellen von Fahrten
//

import SwiftUI

struct EditTripView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TripsViewModel
    @ObservedObject private var settings = AppSettings.shared

    // Mode: Edit existing trip oder Create new trip
    let trip: Trip?

    // Form State
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var startBatteryPercent: String
    @State private var endBatteryPercent: String
    @State private var startOdometer: String
    @State private var endOdometer: String

    @State private var errorMessage: String?
    @State private var showingError = false

    private var isEditMode: Bool {
        trip != nil
    }

    init(viewModel: TripsViewModel, trip: Trip? = nil) {
        self.viewModel = viewModel
        self.trip = trip

        // Initialize mit existierenden Werten (Edit) oder Defaults (Create)
        if let trip = trip {
            _startDate = State(initialValue: trip.startDate ?? Date())
            _endDate = State(initialValue: trip.endDate ?? Date())
            _startBatteryPercent = State(initialValue: String(format: "%.0f", trip.startBatteryPercent))
            _endBatteryPercent = State(initialValue: String(format: "%.0f", trip.endBatteryPercent))
            _startOdometer = State(initialValue: String(format: "%.0f", trip.startOdometer))
            _endOdometer = State(initialValue: String(format: "%.0f", trip.endOdometer))
        } else {
            let now = Date()
            _startDate = State(initialValue: now.addingTimeInterval(-3600)) // 1h ago
            _endDate = State(initialValue: now)
            _startBatteryPercent = State(initialValue: "80")
            _endBatteryPercent = State(initialValue: "60")
            _startOdometer = State(initialValue: "")
            _endOdometer = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Start-Daten
                Section {
                    DatePicker("Datum & Uhrzeit", selection: $startDate)

                    HStack {
                        Label("Batterie", systemImage: "bolt.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        TextField("80", text: $startBatteryPercent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Kilometerstand", systemImage: "road.lanes")
                            .foregroundStyle(.blue)
                        Spacer()
                        TextField("49000", text: $startOdometer)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Start")
                }

                // End-Daten
                Section {
                    DatePicker("Datum & Uhrzeit", selection: $endDate)

                    HStack {
                        Label("Batterie", systemImage: "bolt.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        TextField("60", text: $endBatteryPercent)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Kilometerstand", systemImage: "road.lanes")
                            .foregroundStyle(.blue)
                        Spacer()
                        TextField("49045", text: $endOdometer)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Ende")
                }

                // Preview (nur wenn alle Werte gültig)
                if let preview = calculatePreview() {
                    Section {
                        HStack {
                            Text("Dauer")
                            Spacer()
                            Text(preview.duration)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Strecke")
                            Spacer()
                            Text("\(Int(preview.distance)) km")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Batterie verbraucht")
                            Spacer()
                            Text(String(format: "%.1f%%", preview.batteryUsed))
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Kosten")
                            Spacer()
                            Text(preview.cost, format: .currency(code: "EUR"))
                                .fontWeight(.semibold)
                        }
                    } header: {
                        Text("Vorschau")
                    }
                }
            }
            .navigationTitle(isEditMode ? "Fahrt bearbeiten" : "Fahrt erstellen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Speichern" : "Erstellen") {
                        saveTrip()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Fehler", isPresented: $showingError) {
                Button("OK") {
                    showingError = false
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        // Batterie ist PFLICHT
        guard let startBattery = Double(startBatteryPercent),
              let endBattery = Double(endBatteryPercent) else {
            return false
        }

        // Datum-Validierung
        guard endDate > startDate else { return false }

        // Batterie-Validierung
        guard startBattery >= 0 && startBattery <= 100 else { return false }
        guard endBattery >= 0 && endBattery <= 100 else { return false }

        // Odometer-Validierung (OPTIONAL - nur wenn beide angegeben)
        if !startOdometer.isEmpty && !endOdometer.isEmpty {
            guard let startKm = Double(startOdometer),
                  let endKm = Double(endOdometer),
                  startKm >= 0,
                  endKm > startKm else {
                return false
            }
        }

        return true
    }

    // MARK: - Preview Calculation

    private struct PreviewData {
        let duration: String
        let distance: Double
        let batteryUsed: Double
        let cost: Double
    }

    private func calculatePreview() -> PreviewData? {
        guard let startBattery = Double(startBatteryPercent),
              let endBattery = Double(endBatteryPercent) else {
            return nil
        }

        guard isValid else { return nil }

        // Dauer
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        let durationString = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"

        // Strecke (OPTIONAL - nur wenn angegeben)
        let distance: Double
        if let startKm = Double(startOdometer),
           let endKm = Double(endOdometer) {
            distance = endKm - startKm
        } else {
            distance = 0
        }

        // Batterie
        let batteryUsed = startBattery - endBattery

        // Kosten
        let costPerPercent = settings.costPerPercent(for: startDate)
        let cost = batteryUsed * costPerPercent

        return PreviewData(
            duration: durationString,
            distance: distance,
            batteryUsed: batteryUsed,
            cost: cost
        )
    }

    // MARK: - Save

    private func saveTrip() {
        guard isValid else {
            errorMessage = "Bitte überprüfe deine Eingaben"
            showingError = true
            return
        }

        guard let startBattery = Double(startBatteryPercent),
              let endBattery = Double(endBatteryPercent) else {
            errorMessage = "Ungültige Zahlenwerte"
            showingError = true
            return
        }

        // km-Stand ist optional - leer = 0
        let startKm = Double(startOdometer) ?? 0.0
        let endKm = Double(endOdometer) ?? 0.0

        if isEditMode, let trip = trip {
            // Update existing trip
            viewModel.updateTrip(
                trip,
                startDate: startDate,
                endDate: endDate,
                startBatteryPercent: startBattery,
                endBatteryPercent: endBattery,
                startOdometer: startKm,
                endOdometer: endKm
            )
        } else {
            // Create new trip
            viewModel.createManualTrip(
                startDate: startDate,
                endDate: endDate,
                startBatteryPercent: startBattery,
                endBatteryPercent: endBattery,
                startOdometer: startKm,
                endOdometer: endKm
            )
        }

        dismiss()
    }
}

#Preview {
    let trip = Trip(context: PersistenceController.preview.container.viewContext)
    trip.id = UUID()
    trip.startDate = Date().addingTimeInterval(-3600)
    trip.endDate = Date()
    trip.startBatteryPercent = 80
    trip.endBatteryPercent = 62
    trip.startOdometer = 49000
    trip.endOdometer = 49045

    return EditTripView(
        viewModel: TripsViewModel(context: PersistenceController.preview.container.viewContext),
        trip: trip
    )
}
