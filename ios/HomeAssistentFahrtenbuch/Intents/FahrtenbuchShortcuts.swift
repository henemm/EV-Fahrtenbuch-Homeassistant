//
//  FahrtenbuchShortcuts.swift
//  HomeAssistent Fahrtenbuch
//
//  App Shortcuts Provider - Registriert Shortcuts in der Kurzbefehle-App
//

import AppIntents

struct FahrtenbuchShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTripIntent(),
            phrases: [
                "Fahrt starten in \(.applicationName)",
                "Neue Fahrt in \(.applicationName)",
                "Starte Fahrt in \(.applicationName)"
            ],
            shortTitle: "Fahrt starten",
            systemImageName: "car.fill"
        )

        AppShortcut(
            intent: EndTripIntent(),
            phrases: [
                "Fahrt beenden in \(.applicationName)",
                "Beende Fahrt in \(.applicationName)",
                "Fahrt stoppen in \(.applicationName)"
            ],
            shortTitle: "Fahrt beenden",
            systemImageName: "car.fill.badge.xmark"
        )
    }
}
