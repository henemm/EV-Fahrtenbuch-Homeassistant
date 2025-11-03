//
//  LiveActivityManager.swift
//  HomeAssistent Fahrtenbuch
//
//  LiveActivity Management - iOS 16.1+
//  Keine Duplikation: Verwendet Shared Models aus Widget Extension
//

import Foundation
import ActivityKit
import SwiftUI

@available(iOS 16.1, *)
@MainActor
final class LiveActivityManager {

    static let shared = LiveActivityManager()

    private var currentActivity: Activity<TripActivityAttributes>?

    private init() {}

    // MARK: - Public Methods

    /// Startet LiveActivity für eine Fahrt
    func startActivity(for trip: Trip) {
        print("🔍 LiveActivityManager.startActivity called")

        // Cleanup alte Activity (falls vorhanden)
        endActivity()

        guard let tripId = trip.id,
              let startDate = trip.startDate else {
            print("❌ LiveActivity: Trip hat keine ID oder StartDate")
            return
        }

        print("🔍 Creating TripActivityAttributes for trip: \(tripId)")

        let attributes = TripActivityAttributes(
            tripId: tripId,
            startDate: startDate,
            startBatteryPercent: trip.startBatteryPercent,
            startOdometer: trip.startOdometer
        )

        let initialState = TripActivityAttributes.ContentState(
            durationSeconds: 0,
            lastUpdate: Date()
        )

        print("🔍 Requesting LiveActivity from ActivityKit...")

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )

            currentActivity = activity

            // Auto-Update Timer starten
            startAutoUpdate()

            print("✅ LiveActivity ERFOLGREICH gestartet für Trip: \(tripId)")
            print("✅ Activity ID: \(activity.id)")
            print("✅ Activity State: \(activity.activityState)")

        } catch {
            print("❌ LiveActivity Start Fehler: \(error)")
            print("❌ Error Details: \(error.localizedDescription)")
            if let activityError = error as? ActivityAuthorizationError {
                print("❌ ActivityAuthorizationError: \(activityError)")
            }
        }
    }

    /// Beendet LiveActivity
    func endActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            print("✅ LiveActivity beendet")
        }
    }

    /// Aktualisiert LiveActivity mit neuer Dauer
    func updateActivity() {
        guard let activity = currentActivity else { return }

        let startDate = activity.attributes.startDate
        let durationSeconds = Date().timeIntervalSince(startDate)

        let updatedState = TripActivityAttributes.ContentState(
            durationSeconds: durationSeconds,
            lastUpdate: Date()
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }

    // MARK: - Auto Update

    nonisolated(unsafe) private var updateTimer: Timer?

    private func startAutoUpdate() {
        stopAutoUpdate()

        // Update alle 60 Sekunden
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateActivity()
            }
        }
    }

    nonisolated private func stopAutoUpdate() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    deinit {
        stopAutoUpdate()
    }
}
