//
//  TripRowView.swift
//  HomeAssistent Fahrtenbuch
//
//  Einzelne Fahrt-Karte (Row)
//

import SwiftUI

struct TripRowView: View {

    let trip: Trip
    let settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Datum + Dauer
            HStack {
                Text(trip.startDateFormatted)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if let endTime = trip.endDateFormatted {
                    Text("→ \(endTime)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(trip.durationFormatted)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            // Batterie + Strecke
            HStack(spacing: 16) {
                // Batterie
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.green)

                    Text("\(Int(trip.startBatteryPercent))% → \(Int(trip.endBatteryPercent ?? 0))%")
                        .font(.headline)
                }

                Divider()
                    .frame(height: 20)

                // Strecke
                HStack(spacing: 8) {
                    Image(systemName: "road.lanes")
                        .foregroundStyle(.blue)

                    Text("\(Int(trip.distance)) km")
                        .font(.headline)
                }

                Spacer()
            }

            // Verbrauch + Kosten
            HStack {
                // Verbrauch
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.1f%% Batterie", trip.batteryUsed))
                        .font(.callout)
                        .fontWeight(.medium)

                    let (costPerPercent, season) = trip.costInfo(settings: settings)
                    Text("\(season): \(String(format: "%.2f", costPerPercent)) €/%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Kosten
                let costPerPercent = settings.costPerPercent(for: trip.startDate ?? Date())
                Text(trip.cost(costPerPercent: costPerPercent), format: .currency(code: "EUR"))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
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

    return TripRowView(trip: trip, settings: .shared)
        .padding()
}
