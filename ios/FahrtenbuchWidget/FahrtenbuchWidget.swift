//
//  FahrtenbuchWidget.swift
//  FahrtenbuchWidget
//
//  Widget + LiveActivity Bundle
//  iOS 18 / Swift 6
//

import WidgetKit
import SwiftUI
import ActivityKit

// MARK: - Widget Bundle

@main
@available(iOS 16.0, *)
struct FahrtenbuchWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Home Screen Widget
        FahrtenbuchWidget()

        // LiveActivity (iOS 16.1+)
        if #available(iOS 16.1, *) {
            TripLiveActivity()
        }
    }
}

// MARK: - Home Screen Widget

@available(iOS 16.0, *)
struct FahrtenbuchWidget: Widget {
    let kind: String = "FahrtenbuchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TripWidgetProvider()) { entry in
            TripWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fahrtenbuch")
        .description("Schnellzugriff auf laufende Fahrten")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled() // iOS 17+: Volle Kontrolle über Margins
    }
}

// MARK: - Widget Entry View

@available(iOS 16.0, *)
struct TripWidgetEntryView: View {

    let entry: TripWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    @ViewBuilder
    private var smallWidget: some View {
        if let tripInfo = entry.tripInfo {
            ActiveTripWidgetView(tripInfo: tripInfo)
        } else {
            StartTripWidgetView(isConfigured: entry.isConfigured)
        }
    }

    @ViewBuilder
    private var mediumWidget: some View {
        if let tripInfo = entry.tripInfo {
            MediumTripWidgetView(tripInfo: tripInfo)
        } else {
            StartTripWidgetView(isConfigured: entry.isConfigured)
        }
    }
}

// MARK: - LiveActivity

@available(iOS 16.1, *)
struct TripLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "car.fill")
                        .font(.title3)
                        .foregroundStyle(.green)

                    Text("Fahrt läuft")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(formatDuration(context.state.durationSeconds))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }

                Divider()
                    .overlay(.quaternary)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Batterie")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                        }

                        Text("\(Int(context.attributes.startBatteryPercent))%")
                            .font(.callout)
                            .fontWeight(.medium)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Start")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "road.lanes")
                                .font(.caption2)
                        }

                        Text("\(Int(context.attributes.startOdometer)) km")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundStyle(.green)

                            Text(formatDuration(context.state.durationSeconds))
                                .font(.title)
                                .fontWeight(.semibold)
                                .monospacedDigit()
                        }

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🔋 Batterie")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(context.attributes.startBatteryPercent))%")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("🛣️ Odometer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("\(Int(context.attributes.startOdometer)) km")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } compactTrailing: {
                HStack(spacing: 6) {
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text(formatCompactDuration(context.state.durationSeconds))
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            } minimal: {
                Image(systemName: "car.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
    }

    // Helper Functions
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func formatCompactDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
