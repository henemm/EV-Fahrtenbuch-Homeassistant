//
//  DeepLinkHandler.swift
//  HomeAssistent Fahrtenbuch
//
//  Deep Link / URL Scheme Handler für Kurzbefehle-Integration
//

import Foundation
import SwiftUI

enum DeepLinkAction: Equatable {
    case startTrip
    case endTrip
}

@MainActor
class DeepLinkHandler: ObservableObject {

    @Published var pendingAction: DeepLinkAction?

    static let shared = DeepLinkHandler()

    private init() {}

    /// Verarbeitet eingehende URL (fahrtenbuch://start oder fahrtenbuch://end)
    func handle(url: URL) {
        guard url.scheme == "fahrtenbuch" else {
            print("❌ DeepLink: Unbekanntes URL Scheme: \(url.scheme ?? "nil")")
            return
        }

        switch url.host {
        case "start":
            print("🔗 DeepLink: Fahrt starten angefordert")
            pendingAction = .startTrip

        case "end":
            print("🔗 DeepLink: Fahrt beenden angefordert")
            pendingAction = .endTrip

        default:
            print("❌ DeepLink: Unbekannte Action: \(url.host ?? "nil")")
        }
    }

    /// Markiert Action als verarbeitet
    func clearPendingAction() {
        pendingAction = nil
    }
}
