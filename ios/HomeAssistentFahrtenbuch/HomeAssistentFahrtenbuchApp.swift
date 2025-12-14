//
//  HomeAssistentFahrtenbuchApp.swift
//  HomeAssistent Fahrtenbuch
//
//  App Entry Point
//

import SwiftUI

@main
struct HomeAssistentFahrtenbuchApp: App {

    let persistenceController: PersistenceController
    @StateObject private var deepLinkHandler = DeepLinkHandler.shared

    // MARK: - UI Testing Support

    /// Prüft ob App im UI-Test-Modus läuft
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    /// Prüft ob Demo-Modus via Launch-Argument aktiviert ist
    static var isDemoModeFromLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("--demo-mode")
    }

    /// Prüft ob Netzwerkfehler simuliert werden sollen
    static var shouldSimulateNetworkError: Bool {
        ProcessInfo.processInfo.arguments.contains("--simulate-network-error")
    }

    /// Prüft ob Settings zurückgesetzt werden sollen
    static var shouldResetSettings: Bool {
        ProcessInfo.processInfo.arguments.contains("--reset-settings")
    }

    init() {
        // In-Memory Persistence für UI-Tests
        if Self.isUITesting {
            persistenceController = PersistenceController(inMemory: true)
        } else {
            persistenceController = PersistenceController.shared
        }

        // Settings für UI-Tests konfigurieren
        if Self.isUITesting {
            configureForUITesting()
        }
    }

    private func configureForUITesting() {
        let settings = AppSettings.shared

        if Self.shouldResetSettings {
            settings.homeAssistantURL = ""
            settings.homeAssistantToken = ""
            settings.batteryEntityId = ""
            settings.odometerEntityId = ""
            settings.demoMode = false
        } else if Self.isDemoModeFromLaunch {
            settings.demoMode = true
            // Minimale Konfiguration für Demo-Modus
            settings.homeAssistantURL = "https://demo.home-assistant.io"
            settings.homeAssistantToken = "demo_token"
            settings.batteryEntityId = "sensor.demo_battery"
            settings.odometerEntityId = "sensor.demo_odometer"
        }

        // Netzwerkfehler-Simulation wird im ViewModel behandelt
        // via Environment oder separatem Flag
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(deepLinkHandler)
                .environment(\.simulateNetworkError, Self.shouldSimulateNetworkError)
                .onOpenURL { url in
                    deepLinkHandler.handle(url: url)
                }
        }
    }
}

// MARK: - Environment Key für Netzwerkfehler-Simulation

private struct SimulateNetworkErrorKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var simulateNetworkError: Bool {
        get { self[SimulateNetworkErrorKey.self] }
        set { self[SimulateNetworkErrorKey.self] = newValue }
    }
}
