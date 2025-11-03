//
//  AppSettings.swift
//  HomeAssistent Fahrtenbuch
//
//  App-Einstellungen mit AppStorage + Keychain für Token
//

import Foundation
import SwiftUI

@MainActor
class AppSettings: ObservableObject {

    static let shared = AppSettings()

    // MARK: - Home Assistant Settings (AppStorage)

    @AppStorage("ha_url")
    var homeAssistantURL: String = ""

    @AppStorage("battery_entity_id")
    var batteryEntityId: String = "sensor.enyaq_battery_level"

    @AppStorage("odometer_entity_id")
    var odometerEntityId: String = "sensor.enyaq_odometer"

    // MARK: - Demo Mode (für App Store Review)

    @AppStorage("demo_mode")
    var demoMode: Bool = false

    // MARK: - Debug Logging (API Polling während Fahrt)

    @AppStorage("debug_logging_enabled")
    var debugLoggingEnabled: Bool = false

    // MARK: - Vehicle Settings

    @AppStorage("vehicle_name")
    var vehicleName: String = "Enyaq"

    // MARK: - Pricing Settings (Batterie-Prozent basiert)

    @AppStorage("cost_per_percent_winter")
    var costPerPercentWinter: Double = 0.40 // Nov-März (Monate 11, 12, 1, 2, 3)

    @AppStorage("cost_per_percent_summer")
    var costPerPercentSummer: Double = 0.20 // Apr-Okt (Monate 4-10)

    // MARK: - Computed

    /// Gibt den Preis pro Batterie-Prozent für einen bestimmten Monat zurück
    func costPerPercent(for date: Date) -> Double {
        let month = Calendar.current.component(.month, from: date)
        // Winter: November(11), Dezember(12), Januar(1), Februar(2), März(3)
        if month < 4 || month > 10 {
            return costPerPercentWinter
        } else {
            return costPerPercentSummer
        }
    }

    // MARK: - Token (Keychain)

    private let keychainService = KeychainService.shared

    var homeAssistantToken: String {
        get {
            (try? keychainService.getToken()) ?? ""
        }
        set {
            if newValue.isEmpty {
                try? keychainService.deleteToken()
            } else {
                try? keychainService.saveToken(newValue)
            }
            objectWillChange.send()
        }
    }

    var hasToken: Bool {
        keychainService.hasToken()
    }

    // MARK: - Validation

    var isConfigured: Bool {
        // Im Demo-Modus ist keine Konfiguration erforderlich
        if demoMode {
            return true
        }

        return !homeAssistantURL.isEmpty &&
        hasToken &&
        !batteryEntityId.isEmpty &&
        !odometerEntityId.isEmpty
    }

    // MARK: - Computed

    var homeAssistantURLFormatted: String {
        homeAssistantURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    // MARK: - Reset

    func reset() {
        homeAssistantURL = ""
        batteryEntityId = "sensor.enyaq_battery_level"
        odometerEntityId = "sensor.enyaq_odometer"
        vehicleName = "Enyaq"
        costPerPercentWinter = 0.40
        costPerPercentSummer = 0.20
        homeAssistantToken = ""
    }

    private init() {}
}
