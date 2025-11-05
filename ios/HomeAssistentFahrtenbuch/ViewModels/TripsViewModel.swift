//
//  TripsViewModel.swift
//  HomeAssistent Fahrtenbuch
//
//  Business Logic für Fahrt-Tracking
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class TripsViewModel: ObservableObject {

    @Published var activeTrip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let viewContext: NSManagedObjectContext
    private let settings: AppSettings
    private let haService: HomeAssistantService
    private let debugLogger: TripDebugLogger
    private let widgetService: WidgetDataService
    private var liveActivityManager: AnyObject?  // Type-erased LiveActivityManager for iOS 18+

    init(
        context: NSManagedObjectContext,
        settings: AppSettings = .shared,
        haService: HomeAssistantService = .shared,
        debugLogger: TripDebugLogger = .shared,
        widgetService: WidgetDataService = .shared
    ) {
        self.viewContext = context
        self.settings = settings
        self.haService = haService
        self.debugLogger = debugLogger
        self.widgetService = widgetService

        print("🔍 TripsViewModel.init: iOS Version Check...")
        // LiveActivity Manager (iOS 16.1+)
        if #available(iOS 16.1, *) {
            print("✅ iOS 16.1+ verfügbar, initialisiere LiveActivityManager")
            self.liveActivityManager = LiveActivityManager.shared
            print("✅ LiveActivityManager initialisiert: \(self.liveActivityManager != nil)")
        } else {
            print("❌ iOS Version < 16.1, LiveActivity nicht verfügbar")
        }

        // Prüfe ob aktive Fahrt existiert
        fetchActiveTrip()

        // Widget mit aktuellem Status aktualisieren
        widgetService.updateWidget(with: activeTrip)
        widgetService.updateConfigurationStatus(isConfigured: settings.isConfigured)

        // LiveActivity wiederherstellen (falls App gecrasht ist)
        if #available(iOS 16.1, *), let activeTrip = activeTrip,
           let manager = liveActivityManager as? LiveActivityManager {
            manager.startActivity(for: activeTrip)
        }
    }

    // MARK: - Fetch Active Trip

    func fetchActiveTrip() {
        let request = PersistenceController.fetchActiveTrip()

        do {
            let results = try viewContext.fetch(request)
            activeTrip = results.first
        } catch {
            print("Fehler beim Laden der aktiven Fahrt: \(error)")
        }
    }

    // MARK: - Start Trip

    func startTrip() async {
        guard settings.isConfigured else {
            errorMessage = "Bitte konfiguriere erst Home Assistant in den Einstellungen"
            return
        }

        guard activeTrip == nil else {
            errorMessage = "Es läuft bereits eine Fahrt"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Hole Fahrzeugdaten (Demo oder echte API)
            let vehicleData: VehicleData
            if settings.demoMode {
                vehicleData = await haService.getDemoVehicleData()
            } else {
                vehicleData = try await haService.getVehicleData(
                    url: settings.homeAssistantURLFormatted,
                    token: settings.homeAssistantToken,
                    batteryEntityId: settings.batteryEntityId,
                    odometerEntityId: settings.odometerEntityId
                )
            }

            // Erstelle neue Fahrt
            let trip = Trip(context: viewContext)
            trip.id = UUID()
            trip.startDate = vehicleData.timestamp
            trip.startBatteryPercent = vehicleData.batteryPercent
            trip.startOdometer = vehicleData.odometerKm
            trip.endDate = nil
            trip.endBatteryPercent = 0
            trip.endOdometer = 0

            // Speichern
            try viewContext.save()

            activeTrip = trip

            // Debug-Logging starten (falls aktiviert)
            if settings.debugLoggingEnabled {
                debugLogger.startLogging(haService: haService, settings: settings)
            }

            // Widget aktualisieren
            widgetService.updateWidget(with: trip)

            // LiveActivity starten (iOS 16.1+)
            print("🔍 Trying to start LiveActivity...")
            print("🔍 liveActivityManager is nil? \(liveActivityManager == nil)")

            if #available(iOS 16.1, *) {
                print("✅ iOS 16.1+ Check passed")
                if let manager = liveActivityManager as? LiveActivityManager {
                    print("✅ Cast to LiveActivityManager successful")
                    manager.startActivity(for: trip)
                } else {
                    print("❌ Cast to LiveActivityManager failed - liveActivityManager type: \(type(of: liveActivityManager))")
                }
            } else {
                print("❌ iOS Version Check failed")
            }

        } catch let error as HomeAssistantError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - End Trip

    func endTrip() async {
        guard let trip = activeTrip else {
            errorMessage = "Keine aktive Fahrt gefunden"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // Hole Fahrzeugdaten (Demo oder echte API)
            let vehicleData: VehicleData
            if settings.demoMode {
                vehicleData = await haService.getDemoVehicleData()
            } else {
                vehicleData = try await haService.getVehicleData(
                    url: settings.homeAssistantURLFormatted,
                    token: settings.homeAssistantToken,
                    batteryEntityId: settings.batteryEntityId,
                    odometerEntityId: settings.odometerEntityId
                )
            }

            // Aktualisiere Fahrt
            trip.endDate = vehicleData.timestamp
            trip.endBatteryPercent = vehicleData.batteryPercent
            trip.endOdometer = vehicleData.odometerKm

            // Speichern
            try viewContext.save()

            activeTrip = nil

            // Debug-Logging stoppen (falls aktiv)
            if debugLogger.isLogging {
                debugLogger.stopLogging()
            }

            // Widget aktualisieren (keine aktive Fahrt mehr)
            widgetService.updateWidget(with: nil)

            // LiveActivity beenden (iOS 16.1+)
            if #available(iOS 16.1, *),
               let manager = liveActivityManager as? LiveActivityManager {
                manager.endActivity()
            }

        } catch let error as HomeAssistantError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Unbekannter Fehler: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Update Trip

    func updateTrip(
        _ trip: Trip,
        startDate: Date,
        endDate: Date,
        startBatteryPercent: Double,
        endBatteryPercent: Double,
        startOdometer: Double,
        endOdometer: Double
    ) {
        trip.startDate = startDate
        trip.endDate = endDate
        trip.startBatteryPercent = startBatteryPercent
        trip.endBatteryPercent = endBatteryPercent
        trip.startOdometer = startOdometer
        trip.endOdometer = endOdometer

        do {
            try viewContext.save()

            // Force refresh to ensure @FetchRequest sees changes
            viewContext.refresh(trip, mergeChanges: false)
            viewContext.processPendingChanges()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }

    // MARK: - Create Manual Trip

    func createManualTrip(
        startDate: Date,
        endDate: Date,
        startBatteryPercent: Double,
        endBatteryPercent: Double,
        startOdometer: Double,
        endOdometer: Double
    ) {
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = startDate
        trip.endDate = endDate
        trip.startBatteryPercent = startBatteryPercent
        trip.endBatteryPercent = endBatteryPercent
        trip.startOdometer = startOdometer
        trip.endOdometer = endOdometer

        do {
            try viewContext.save()

            // Force refresh to ensure @FetchRequest sees new trip
            viewContext.processPendingChanges()
        } catch {
            errorMessage = "Fehler beim Erstellen: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Trip

    func deleteTrip(_ trip: Trip) {
        viewContext.delete(trip)

        do {
            try viewContext.save()
        } catch {
            errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
        }
    }

    // MARK: - Monthly Summary

    struct MonthlySummary {
        let month: Date
        let tripCount: Int
        let totalKwh: Double
        let totalCost: Double
        let totalDistance: Double
        let averageConsumption: Double
    }

    func monthlySummary(for trips: [Trip]) -> MonthlySummary? {
        guard let firstTrip = trips.first,
              let startDate = firstTrip.startDate else { return nil }

        let totalBatteryPercent = trips.reduce(0.0) { $0 + $1.batteryUsed }

        // Kosten: Jede Fahrt wird mit dem Tarif ihres Monats berechnet
        let totalCost = trips.reduce(0.0) { sum, trip in
            guard let tripDate = trip.startDate else { return sum }
            let costPerPercent = settings.costPerPercent(for: tripDate)
            return sum + trip.cost(costPerPercent: costPerPercent)
        }

        let totalKwh = trips.reduce(0.0) { $0 + $1.kwhUsed() }
        let totalDistance = trips.reduce(0.0) { $0 + $1.distance }
        let averageConsumption = totalDistance > 0 ? (totalKwh / totalDistance) * 100 : 0

        return MonthlySummary(
            month: startDate,
            tripCount: trips.count,
            totalKwh: totalKwh,
            totalCost: totalCost,
            totalDistance: totalDistance,
            averageConsumption: averageConsumption
        )
    }
}
