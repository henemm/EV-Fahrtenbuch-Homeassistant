//
//  StartTripIntent.swift
//  HomeAssistent Fahrtenbuch
//
//  App Intent für "Fahrt starten" in der Kurzbefehle-App
//

import AppIntents
import Foundation

struct StartTripIntent: AppIntent {

    nonisolated(unsafe) static var title: LocalizedStringResource = "Fahrt starten"
    nonisolated(unsafe) static var description: IntentDescription = IntentDescription("Startet eine neue Fahrt im Fahrtenbuch")

    nonisolated(unsafe) static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        print("🎯 App Intent: Fahrt starten aufgerufen")

        // Nutze existierende DeepLink-Logik für Dialoge
        DeepLinkHandler.shared.pendingAction = .startTrip

        return .result()
    }
}
