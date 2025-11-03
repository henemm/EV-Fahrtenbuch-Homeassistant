//
//  TripWidgetView.swift
//  FahrtenbuchWidget
//
//  Widget Views - iOS 18 Liquid Glass Design
//

import SwiftUI
import WidgetKit

// MARK: - Widget Entry

struct TripWidgetEntry: TimelineEntry {
    let date: Date
    let tripInfo: TripInfo?
    let isConfigured: Bool
}

// MARK: - Active Trip Widget View

@available(iOS 16.0, *)
struct ActiveTripWidgetView: View {

    let tripInfo: TripInfo
    let entryDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "car.fill")
                    .font(.body)
                    .foregroundStyle(.green)

                Text("Fahrt läuft")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)

                Spacer()
            }

            Divider()
                .overlay(.quaternary)

            // Dauer (prominent)
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(tripInfo.formattedDuration(at: entryDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            // Statistiken
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text("\(Int(tripInfo.startBatteryPercent))% Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                        .font(.caption2)
                        .foregroundStyle(.blue)

                    Text("\(Int(tripInfo.startOdometer)) km")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            // Liquid Glass Effect
            ZStack {
                LinearGradient(
                    colors: [.green.opacity(0.05), .green.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Start Trip Widget View

@available(iOS 16.0, *)
struct StartTripWidgetView: View {

    let isConfigured: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(.green.gradient)
                    .frame(width: 60, height: 60)
                    .shadow(color: .green.opacity(0.3), radius: 8, y: 4)

                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            // Text
            VStack(spacing: 4) {
                Text("Fahrt starten")
                    .font(.callout)
                    .fontWeight(.semibold)

                if !isConfigured {
                    Text("Erst konfigurieren")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            // Liquid Glass Effect
            ZStack {
                LinearGradient(
                    colors: [.gray.opacity(0.05), .gray.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(.ultraThinMaterial)
            }
        }
        .widgetURL(URL(string: "fahrtenbuch://start"))
    }
}

// MARK: - Medium Widget View

@available(iOS 16.0, *)
struct MediumTripWidgetView: View {

    let tripInfo: TripInfo
    let entryDate: Date

    var body: some View {
        HStack(spacing: 16) {
            // Links: Dauer + Icon
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Text("Fahrt läuft")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }

                Text(tripInfo.formattedDuration(at: entryDate))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            Spacer()

            Divider()

            // Rechts: Statistiken
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Batterie")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(tripInfo.startBatteryPercent))%")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "road.lanes")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Odometer")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(tripInfo.startOdometer)) km")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            // Liquid Glass Effect
            ZStack {
                LinearGradient(
                    colors: [.green.opacity(0.05), .green.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(.ultraThinMaterial)
            }
        }
    }
}
