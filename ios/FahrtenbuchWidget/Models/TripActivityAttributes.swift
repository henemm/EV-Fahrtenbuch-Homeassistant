//
//  TripActivityAttributes.swift
//  FahrtenbuchWidget
//
//  Shared Data Models für Widget + LiveActivity
//  iOS 18 / Swift 6
//

import Foundation
import ActivityKit

// MARK: - LiveActivity Attributes

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamische Werte (ändern sich während Fahrt)
        var durationSeconds: TimeInterval
        var lastUpdate: Date
    }

    // Statische Werte (bleiben während Fahrt gleich)
    var tripId: UUID
    var startDate: Date
    var startBatteryPercent: Double
    var startOdometer: Double
}

// MARK: - Shared Trip Info (Widget + LiveActivity)

struct TripInfo: Codable, Hashable {
    let tripId: UUID
    let startDate: Date
    let startBatteryPercent: Double
    let startOdometer: Double
    var durationSeconds: TimeInterval
    var lastUpdate: Date

    // Computed Properties
    var durationFormatted: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) / 60 % 60
        let seconds = Int(durationSeconds) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var durationCompact: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = Int(durationSeconds) / 60 % 60
        let seconds = Int(durationSeconds) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1 Min"
        }
    }

    // Helper: Berechne aktuelle Dauer basierend auf einem Referenz-Date (für Widgets)
    func currentDuration(at date: Date) -> TimeInterval {
        return date.timeIntervalSince(startDate)
    }

    func formattedDuration(at date: Date) -> String {
        let duration = currentDuration(at: date)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func compactDuration(at date: Date) -> String {
        let duration = currentDuration(at: date)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1 Min"
        }
    }
}

// MARK: - Shared Data Provider

@available(iOS 16.0, *)
final class TripDataProvider: Sendable {

    static let shared = TripDataProvider()
    private let appGroupID = "group.henemm.fahrtenbuch"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // MARK: - Load Trip Info

    func loadActiveTripInfo() -> TripInfo? {
        guard let userDefaults = userDefaults else {
            return nil
        }

        guard userDefaults.bool(forKey: "widget_has_active_trip") else {
            return nil
        }

        guard let tripIdString = userDefaults.string(forKey: "widget_trip_id"),
              let tripId = UUID(uuidString: tripIdString),
              let startDateTimestamp = userDefaults.object(forKey: "widget_trip_start_date") as? Double else {
            return nil
        }

        let startBattery = userDefaults.double(forKey: "widget_trip_start_battery")
        let startOdo = userDefaults.double(forKey: "widget_trip_start_odo")
        let startDate = Date(timeIntervalSince1970: startDateTimestamp)

        let durationSeconds = Date().timeIntervalSince(startDate)

        return TripInfo(
            tripId: tripId,
            startDate: startDate,
            startBatteryPercent: startBattery,
            startOdometer: startOdo,
            durationSeconds: durationSeconds,
            lastUpdate: Date()
        )
    }

    func isConfigured() -> Bool {
        guard let userDefaults = userDefaults else {
            return false
        }
        return userDefaults.bool(forKey: "widget_is_configured")
    }
}
