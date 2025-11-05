//
//  EndTripIntent.swift
//  HomeAssistent Fahrtenbuch
//
//  App Intent für "Fahrt beenden" in der Kurzbefehle-App
//

import AppIntents
import Foundation

struct EndTripIntent: AppIntent {

    nonisolated(unsafe) static var title: LocalizedStringResource = "Fahrt beenden"
    nonisolated(unsafe) static var description: IntentDescription = IntentDescription("Beendet die laufende Fahrt im Fahrtenbuch")

    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 App Intent: Fahrt beenden aufgerufen")

        // Nutze existierende DeepLink-Logik für Dialoge
        DeepLinkHandler.shared.pendingAction = .endTrip

        return .result()
    }
}
