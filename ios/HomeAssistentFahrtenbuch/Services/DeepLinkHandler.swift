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
            print("Unbekanntes URL Scheme: \(url.scheme ?? "nil")")
            return
        }

        switch url.host {
        case "start":
            print("Deep Link: Fahrt starten")
            pendingAction = .startTrip

        case "end":
            print("Deep Link: Fahrt beenden")
            pendingAction = .endTrip

        default:
            print("Unbekannte Deep Link Action: \(url.host ?? "nil")")
        }
    }

    /// Markiert Action als verarbeitet
    func clearPendingAction() {
        pendingAction = nil
    }
}
