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
            TripLockScreenView(
                startDate: context.attributes.startDate,
                startBatteryPercent: context.attributes.startBatteryPercent,
                startOdometer: context.attributes.startOdometer
            )
            .activityBackgroundTint(.black.opacity(0.2))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded View
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Auto-Icon + Timer zusammen
                        HStack(spacing: 8) {
                            Image(systemName: "car.fill")
                                .font(.title2)
                                .foregroundStyle(.green)

                            Image(systemName: "timer")
                                .font(.title3)
                                .foregroundStyle(.secondary)

                            Text(context.attributes.startDate, style: .timer)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                        }

                        // Statistiken linksbündig
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text("\(Int(context.attributes.startBatteryPercent))%")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                }
                                Text("Batterie Start")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "road.lanes")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    Text("\(Int(context.attributes.startOdometer)) km")
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                }
                                Text("Kilometerstand")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: "car.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.leading, 5)
            } compactTrailing: {
                Text(context.attributes.startDate, style: .timer)
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .frame(width: 55)
            } minimal: {
                Image(systemName: "car.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
            .contentMargins([.leading, .top, .bottom], 4, for: .compactLeading)
            .contentMargins([.trailing, .top, .bottom], 4, for: .compactTrailing)
            .contentMargins(.all, 4, for: .minimal)
        }
    }

}

// MARK: - Lock Screen View

@available(iOS 16.0, *)
private struct TripLockScreenView: View {
    let startDate: Date
    let startBatteryPercent: Double
    let startOdometer: Double

    var body: some View {
        HStack {
            // Links: Auto-Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.28))
                    .frame(width: 40, height: 40)
                Image(systemName: "car.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.leading)

            Spacer()

            // Mitte: Timer
            Text(startDate, style: .timer)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
