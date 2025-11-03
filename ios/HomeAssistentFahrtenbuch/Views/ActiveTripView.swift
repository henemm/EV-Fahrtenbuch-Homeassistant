//
//  ActiveTripView.swift
//  HomeAssistent Fahrtenbuch
//
//  Fullscreen-View für laufende Fahrt
//

import SwiftUI

struct ActiveTripView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var trip: Trip
    @ObservedObject var viewModel: TripsViewModel

    @State private var currentTime = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                // Hintergrund-Gradient
                LinearGradient(
                    colors: [.green.opacity(0.2), .green.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 32) {

                    Spacer()

                    // Pulsierendes Icon
                    Image(systemName: "car.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                        .symbolEffect(.pulse, options: .repeat(.continuous))

                    Text("Fahrt läuft")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Start-Info
                    VStack(spacing: 16) {
                        InfoRow(
                            icon: "clock.fill",
                            label: "Gestartet",
                            value: trip.startDateFormatted
                        )

                        InfoRow(
                            icon: "timer",
                            label: "Dauer",
                            value: formatDuration(trip.durationMinutes)
                        )

                        Divider()

                        InfoRow(
                            icon: "bolt.fill",
                            label: "Batterie Start",
                            value: "\(Int(trip.startBatteryPercent))%"
                        )

                        InfoRow(
                            icon: "road.lanes",
                            label: "Kilometerstand Start",
                            value: "\(Int(trip.startOdometer)) km"
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 10)

                    Spacer()

                    // Fahrt beenden Button
                    Button {
                        Task {
                            await viewModel.endTrip()
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "stop.circle.fill")
                                .font(.title2)

                            Text("Fahrt beenden")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                        .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .sensoryFeedback(.success, trigger: viewModel.activeTrip == nil)
                }
                .padding()

                // Loading Overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zurück") {
                        dismiss()
                    }
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            return "\(hours)h \(mins)min"
        } else {
            return "\(mins)min"
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let trip = Trip(context: context)
    trip.id = UUID()
    trip.startDate = Date().addingTimeInterval(-1800)
    trip.startBatteryPercent = 80
    trip.startOdometer = 49200

    let viewModel = TripsViewModel(context: context)

    return ActiveTripView(trip: trip, viewModel: viewModel)
}
