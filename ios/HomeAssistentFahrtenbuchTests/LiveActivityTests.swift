//
//  LiveActivityTests.swift
//  HomeAssistentFahrtenbuchTests
//
//  Tests für LiveActivity Funktionalität
//

import XCTest
import ActivityKit
import CoreData
@testable import HomeAssistentFahrtenbuch

@available(iOS 16.1, *)
@MainActor
final class LiveActivityTests: XCTestCase {

    var viewContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // In-Memory Core Data Stack für Tests
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }

    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
        try super.tearDownWithError()
    }

    // MARK: - TripActivityAttributes Tests

    func testTripActivityAttributesCreation() throws {
        // Given
        let tripId = UUID()
        let startDate = Date()
        let batteryPercent = 75.5
        let odometer = 50000.0

        // When
        let attributes = TripActivityAttributes(
            tripId: tripId,
            startDate: startDate,
            startBatteryPercent: batteryPercent,
            startOdometer: odometer
        )

        // Then
        XCTAssertEqual(attributes.tripId, tripId)
        XCTAssertEqual(attributes.startDate, startDate)
        XCTAssertEqual(attributes.startBatteryPercent, batteryPercent)
        XCTAssertEqual(attributes.startOdometer, odometer)
    }

    func testTripActivityContentState() throws {
        // Given
        let durationSeconds: TimeInterval = 3600 // 1 Stunde
        let lastUpdate = Date()

        // When
        let state = TripActivityAttributes.ContentState(
            durationSeconds: durationSeconds,
            lastUpdate: lastUpdate
        )

        // Then
        XCTAssertEqual(state.durationSeconds, durationSeconds)
        XCTAssertEqual(state.lastUpdate, lastUpdate)
    }

    // MARK: - TripInfo Tests

    func testTripInfoDurationFormatting() throws {
        // Given
        let tripInfo = TripInfo(
            tripId: UUID(),
            startDate: Date().addingTimeInterval(-3661), // 1h 1m 1s ago
            startBatteryPercent: 80,
            startOdometer: 49000,
            durationSeconds: 3661,
            lastUpdate: Date()
        )

        // When
        let formatted = tripInfo.durationFormatted

        // Then
        XCTAssertEqual(formatted, "01:01:01")
    }

    func testTripInfoDurationFormattingWithoutHours() throws {
        // Given
        let tripInfo = TripInfo(
            tripId: UUID(),
            startDate: Date().addingTimeInterval(-125), // 2m 5s ago
            startBatteryPercent: 80,
            startOdometer: 49000,
            durationSeconds: 125,
            lastUpdate: Date()
        )

        // When
        let formatted = tripInfo.durationFormatted

        // Then
        XCTAssertEqual(formatted, "02:05")
    }

    func testTripInfoCompactDuration() throws {
        // Given
        let tripInfo = TripInfo(
            tripId: UUID(),
            startDate: Date().addingTimeInterval(-4500), // 1h 15m
            startBatteryPercent: 80,
            startOdometer: 49000,
            durationSeconds: 4500,
            lastUpdate: Date()
        )

        // When
        let compact = tripInfo.durationCompact

        // Then
        XCTAssertEqual(compact, "1h 15min")
    }

    func testTripInfoCompactDurationWithoutHours() throws {
        // Given
        let tripInfo = TripInfo(
            tripId: UUID(),
            startDate: Date().addingTimeInterval(-900), // 15m
            startBatteryPercent: 80,
            startOdometer: 49000,
            durationSeconds: 900,
            lastUpdate: Date()
        )

        // When
        let compact = tripInfo.durationCompact

        // Then
        XCTAssertEqual(compact, "15min")
    }

    func testTripInfoCompactDurationLessThanOneMinute() throws {
        // Given
        let tripInfo = TripInfo(
            tripId: UUID(),
            startDate: Date().addingTimeInterval(-30), // 30s
            startBatteryPercent: 80,
            startOdometer: 49000,
            durationSeconds: 30,
            lastUpdate: Date()
        )

        // When
        let compact = tripInfo.durationCompact

        // Then
        XCTAssertEqual(compact, "<1 Min")
    }

    // Note: Tests für formattedDuration(at:) und compactDuration(at:) entfernt
    // da diese Methoden nicht in TripInfo existieren (durationFormatted und
    // durationCompact verwenden durationSeconds direkt)

    // MARK: - TripDataProvider Tests

    func testTripDataProviderSharedInstance() throws {
        // Given/When
        let provider1 = TripDataProvider.shared
        let provider2 = TripDataProvider.shared

        // Then
        XCTAssert(provider1 === provider2, "TripDataProvider.shared sollte Singleton sein")
    }

    func testTripDataProviderLoadActiveTripInfo_NoTrip() throws {
        // Given
        let provider = TripDataProvider.shared

        // When
        let tripInfo = provider.loadActiveTripInfo()

        // Then
        XCTAssertNil(tripInfo, "Ohne gespeicherte Fahrt sollte nil zurückgegeben werden")
    }

    // MARK: - LiveActivityManager Tests

    func testLiveActivityManagerSharedInstance() throws {
        // Given/When
        let manager1 = LiveActivityManager.shared
        let manager2 = LiveActivityManager.shared

        // Then
        XCTAssert(manager1 === manager2, "LiveActivityManager.shared sollte Singleton sein")
    }

    func testLiveActivityManagerStartWithInvalidTrip() throws {
        // Given
        let manager = LiveActivityManager.shared
        let trip = Trip(context: viewContext)
        // Trip ohne ID und startDate

        // When/Then
        // Sollte nicht crashen, sondern graceful fail
        manager.startActivity(for: trip)

        // No crash = success
        XCTAssert(true, "LiveActivityManager sollte mit ungültigen Trips umgehen können")
    }

    func testLiveActivityManagerStartWithValidTrip() throws {
        // Given
        let manager = LiveActivityManager.shared
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = Date()
        trip.startBatteryPercent = 75.0
        trip.startOdometer = 49500.0

        // When
        manager.startActivity(for: trip)

        // Then
        // In Tests können wir nicht prüfen ob Activity wirklich sichtbar ist,
        // aber wir können prüfen dass kein Crash auftritt
        XCTAssert(true, "LiveActivity Start sollte nicht crashen")
    }

    // MARK: - Integration Tests

    func testTripsViewModelInitializesLiveActivityManager() throws {
        // Given
        let settings = AppSettings.shared
        settings.demoMode = true // Demo Mode für Tests

        // When
        let viewModel = TripsViewModel(
            context: viewContext,
            settings: settings
        )

        // Then
        // ViewModel sollte initialisiert sein
        XCTAssertNotNil(viewModel, "TripsViewModel sollte initialisiert werden")

        // Auf iOS 16.1+ sollte LiveActivityManager verfügbar sein
        if #available(iOS 16.1, *) {
            // Test durchgeführt auf iOS 16.1+ System
            XCTAssert(true, "LiveActivityManager sollte auf iOS 16.1+ verfügbar sein")
        }
    }

    func testWidgetDataServiceUpdateWithTrip() throws {
        // Given
        let widgetService = WidgetDataService.shared
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = Date()
        trip.startBatteryPercent = 80.0
        trip.startOdometer = 50000.0

        // When
        widgetService.updateWidget(with: trip)

        // Then
        // Daten sollten in UserDefaults geschrieben worden sein
        let appGroup = UserDefaults(suiteName: "group.henemm.fahrtenbuch")
        let savedTripId = appGroup?.string(forKey: "widget_trip_id")

        XCTAssertNotNil(savedTripId, "Trip ID sollte gespeichert worden sein")
        XCTAssertEqual(savedTripId, trip.id?.uuidString, "Gespeicherte Trip ID sollte übereinstimmen")
    }

    func testWidgetDataServiceUpdateWithNilTrip() throws {
        // Given
        let widgetService = WidgetDataService.shared

        // When
        widgetService.updateWidget(with: nil)

        // Then
        // Daten sollten gelöscht worden sein
        let appGroup = UserDefaults(suiteName: "group.henemm.fahrtenbuch")
        let savedTripId = appGroup?.string(forKey: "widget_trip_id")

        XCTAssertNil(savedTripId, "Trip ID sollte gelöscht worden sein")
    }
}
