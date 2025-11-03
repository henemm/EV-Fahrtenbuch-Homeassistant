//
//  SettingsViewModel.swift
//  HomeAssistent Fahrtenbuch
//
//  Business Logic für Settings-Screen
//

import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {

    @Published var isTestingConnection = false
    @Published var connectionTestResult: ConnectionTestResult?

    private let settings: AppSettings
    private nonisolated(unsafe) let haService: HomeAssistantService

    enum ConnectionTestResult {
        case success(VehicleData)
        case failure(String)
    }

    init(
        settings: AppSettings = .shared,
        haService: HomeAssistantService = .shared
    ) {
        self.settings = settings
        self.haService = haService
    }

    // MARK: - Test Connection

    func testConnection() async {
        guard !settings.homeAssistantURL.isEmpty else {
            connectionTestResult = .failure("Bitte gib eine Home Assistant URL ein")
            return
        }

        guard !settings.homeAssistantToken.isEmpty else {
            connectionTestResult = .failure("Bitte gib einen Token ein")
            return
        }

        isTestingConnection = true
        connectionTestResult = nil

        do {
            // 1. Verbindung testen
            try await haService.testConnection(
                url: settings.homeAssistantURLFormatted,
                token: settings.homeAssistantToken
            )

            // 2. Fahrzeugdaten abrufen (validiert Entity-IDs)
            let vehicleData = try await haService.getVehicleData(
                url: settings.homeAssistantURLFormatted,
                token: settings.homeAssistantToken,
                batteryEntityId: settings.batteryEntityId,
                odometerEntityId: settings.odometerEntityId
            )

            connectionTestResult = .success(vehicleData)

        } catch let error as HomeAssistantError {
            connectionTestResult = .failure(error.localizedDescription)
        } catch {
            connectionTestResult = .failure("Unbekannter Fehler: \(error.localizedDescription)")
        }

        isTestingConnection = false
    }

    // MARK: - Reset

    func resetSettings() {
        settings.reset()
        connectionTestResult = nil
    }

    // MARK: - Validation

    var isURLValid: Bool {
        !settings.homeAssistantURL.isEmpty &&
        (settings.homeAssistantURL.hasPrefix("https://") || settings.homeAssistantURL.hasPrefix("http://"))
    }

    var isTokenValid: Bool {
        settings.hasToken && settings.homeAssistantToken.count > 20
    }

    var canTestConnection: Bool {
        isURLValid && isTokenValid && !settings.batteryEntityId.isEmpty && !settings.odometerEntityId.isEmpty
    }
}
