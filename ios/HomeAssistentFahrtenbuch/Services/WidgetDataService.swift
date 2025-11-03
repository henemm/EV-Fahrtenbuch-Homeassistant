//
//  WidgetDataService.swift
//  HomeAssistent Fahrtenbuch
//
//  Service: Teilt Daten mit Home Screen Widget über App Groups
//

import Foundation
import WidgetKit

@MainActor
class WidgetDataService {

    static let shared = WidgetDataService()

    private let appGroupID = "group.henemm.fahrtenbuch"

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // MARK: - Public Methods

    /// Aktualisiert Widget mit aktiver Fahrt
    func updateWidget(with trip: Trip?) {
        guard let userDefaults = userDefaults else {
            print("❌ Widget: App Group nicht verfügbar")
            return
        }

        if let trip = trip, let tripId = trip.id {
            // Aktive Fahrt
            userDefaults.set(true, forKey: "widget_has_active_trip")
            userDefaults.set(tripId.uuidString, forKey: "widget_trip_id")
            userDefaults.set(trip.startDate?.timeIntervalSince1970 ?? 0, forKey: "widget_trip_start_date")
            userDefaults.set(trip.startBatteryPercent, forKey: "widget_trip_start_battery")
            userDefaults.set(trip.startOdometer, forKey: "widget_trip_start_odo")

            print("✅ Widget: Aktive Fahrt aktualisiert (ID: \(tripId))")

        } else {
            // Keine aktive Fahrt
            userDefaults.set(false, forKey: "widget_has_active_trip")
            userDefaults.removeObject(forKey: "widget_trip_id")
            userDefaults.removeObject(forKey: "widget_trip_start_date")
            userDefaults.removeObject(forKey: "widget_trip_start_battery")
            userDefaults.removeObject(forKey: "widget_trip_start_odo")

            print("✅ Widget: Fahrt beendet")
        }

        // Widget neu laden
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Aktualisiert Widget mit Konfigurationsstatus
    func updateConfigurationStatus(isConfigured: Bool) {
        guard let userDefaults = userDefaults else {
            print("❌ Widget: App Group nicht verfügbar")
            return
        }

        userDefaults.set(isConfigured, forKey: "widget_is_configured")

        // Widget neu laden
        WidgetCenter.shared.reloadAllTimelines()
    }
}
