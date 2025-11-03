//
//  TripWidgetProvider.swift
//  FahrtenbuchWidget
//
//  Widget Timeline Provider - Shared Logic
//

import WidgetKit
import SwiftUI

@available(iOS 16.0, *)
struct TripWidgetProvider: TimelineProvider {

    private let dataProvider = TripDataProvider.shared

    // MARK: - TimelineProvider

    func placeholder(in context: Context) -> TripWidgetEntry {
        TripWidgetEntry(
            date: Date(),
            tripInfo: TripInfo(
                tripId: UUID(),
                startDate: Date().addingTimeInterval(-3600),
                startBatteryPercent: 66,
                startOdometer: 49230,
                durationSeconds: 3600,
                lastUpdate: Date()
            ),
            isConfigured: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TripWidgetEntry) -> Void) {
        let entry = TripWidgetEntry(
            date: Date(),
            tripInfo: dataProvider.loadActiveTripInfo(),
            isConfigured: dataProvider.isConfigured()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TripWidgetEntry>) -> Void) {
        let currentDate = Date()

        let tripInfo = dataProvider.loadActiveTripInfo()
        let isConfigured = dataProvider.isConfigured()

        let entry = TripWidgetEntry(
            date: currentDate,
            tripInfo: tripInfo,
            isConfigured: isConfigured
        )

        // Update-Strategie
        let refreshDate: Date
        if tripInfo != nil {
            // Aktive Fahrt: Update alle 60 Sekunden
            refreshDate = Calendar.current.date(byAdding: .second, value: 60, to: currentDate)!
        } else {
            // Keine Fahrt: Update alle 15 Minuten
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        }

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}
