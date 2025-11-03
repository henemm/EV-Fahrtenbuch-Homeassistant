//
//  MonthSectionHeader.swift
//  HomeAssistent Fahrtenbuch
//
//  Monats-Header mit Zusammenfassung
//

import SwiftUI

struct MonthSectionHeader: View {

    let monthString: String
    let summary: TripsViewModel.MonthlySummary?
    let onExport: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthString)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if onExport != nil {
                    Button(action: { onExport?() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if let summary = summary {
                HStack(spacing: 24) {
                    // Fahrten
                    StatView(
                        icon: "car.fill",
                        value: "\(summary.tripCount)",
                        label: summary.tripCount == 1 ? "Fahrt" : "Fahrten"
                    )

                    // Strecke
                    StatView(
                        icon: "road.lanes",
                        value: "\(Int(summary.totalDistance)) km",
                        label: "Gesamt"
                    )

                    // Verbrauch
                    StatView(
                        icon: "bolt.fill",
                        value: String(format: "%.1f kWh", summary.totalKwh),
                        label: "Verbrauch"
                    )
                }

                // Kosten (hervorgehoben)
                HStack {
                    Text("Gesamtkosten:")
                        .font(.headline)

                    Spacer()

                    Text(summary.totalCost, format: .currency(code: "EUR"))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Stat View Helper

struct StatView: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    let summary = TripsViewModel.MonthlySummary(
        month: Date(),
        tripCount: 12,
        totalKwh: 85.4,
        totalCost: 25.62,
        totalDistance: 450,
        averageConsumption: 18.98
    )

    return MonthSectionHeader(monthString: "November 2025", summary: summary, onExport: nil)
        .padding()
}
