//
//  EditTripViewTests.swift
//  HomeAssistentFahrtenbuchTests
//
//  Tests für Bug 2: Edit Trip erzeugt neuen Eintrag statt zu aktualisieren
//  Root Cause: .sheet(isPresented:) captured tripToEdit bevor State-Update propagiert
//

import XCTest
import CoreData
@testable import HomeAssistentFahrtenbuch

final class EditTripViewTests: XCTestCase {

    var viewContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext
    }

    override func tearDownWithError() throws {
        viewContext = nil
        persistenceController = nil
        try super.tearDownWithError()
    }

    // MARK: - Bug 2: Edit vs Create Mode Tests

    /// Test: EditTripView mit Trip Parameter sollte im Edit-Modus sein
    func test_editTripView_withTrip_shouldBeInEditMode() throws {
        // Arrange: Erstelle einen existierenden Trip
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = Date().addingTimeInterval(-3600)
        trip.endDate = Date()
        trip.startBatteryPercent = 80
        trip.endBatteryPercent = 60
        trip.startOdometer = 49000
        trip.endOdometer = 49050
        try viewContext.save()

        let viewModel = TripsViewModel(context: viewContext)

        // Act: Erstelle EditTripView mit dem Trip
        let editView = EditTripView(viewModel: viewModel, trip: trip)

        // Assert: View sollte im Edit-Modus sein (trip != nil)
        // Da isEditMode private ist, prüfen wir indirekt über das trip property
        XCTAssertNotNil(editView.trip, "EditTripView sollte den Trip haben")
        XCTAssertEqual(editView.trip?.id, trip.id, "EditTripView sollte den korrekten Trip haben")
    }

    /// Test: EditTripView ohne Trip Parameter sollte im Create-Modus sein
    func test_editTripView_withoutTrip_shouldBeInCreateMode() throws {
        // Arrange
        let viewModel = TripsViewModel(context: viewContext)

        // Act: Erstelle EditTripView ohne Trip
        let createView = EditTripView(viewModel: viewModel, trip: nil)

        // Assert: View sollte im Create-Modus sein (trip == nil)
        XCTAssertNil(createView.trip, "EditTripView sollte keinen Trip haben für Create-Modus")
    }

    /// Test: TripsViewModel.updateTrip sollte existierenden Trip aktualisieren, nicht neu erstellen
    func test_updateTrip_shouldUpdateExisting_notCreateNew() throws {
        // Arrange: Erstelle einen existierenden Trip
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = Date().addingTimeInterval(-3600)
        trip.endDate = Date()
        trip.startBatteryPercent = 80
        trip.endBatteryPercent = 60
        trip.startOdometer = 49000
        trip.endOdometer = 49050
        try viewContext.save()

        let initialTripCount = try viewContext.count(for: Trip.fetchRequest())
        let viewModel = TripsViewModel(context: viewContext)

        // Act: Update den Trip mit neuen Werten
        viewModel.updateTrip(
            trip,
            startDate: trip.startDate!,
            endDate: trip.endDate!,
            startBatteryPercent: 75,  // Geändert
            endBatteryPercent: 55,     // Geändert
            startOdometer: 49000,
            endOdometer: 49050
        )

        // Assert: Trip-Anzahl sollte gleich bleiben (kein neuer Trip erstellt)
        let finalTripCount = try viewContext.count(for: Trip.fetchRequest())
        XCTAssertEqual(initialTripCount, finalTripCount, "Update sollte keinen neuen Trip erstellen")

        // Assert: Existierender Trip sollte aktualisiert sein
        XCTAssertEqual(trip.startBatteryPercent, 75, "startBatteryPercent sollte aktualisiert sein")
        XCTAssertEqual(trip.endBatteryPercent, 55, "endBatteryPercent sollte aktualisiert sein")
    }

    /// Test: TripsViewModel.createManualTrip sollte neuen Trip erstellen
    func test_createManualTrip_shouldCreateNewTrip() throws {
        // Arrange
        let initialTripCount = try viewContext.count(for: Trip.fetchRequest())
        let viewModel = TripsViewModel(context: viewContext)

        // Act: Erstelle neuen Trip
        viewModel.createManualTrip(
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date(),
            startBatteryPercent: 80,
            endBatteryPercent: 60,
            startOdometer: 49000,
            endOdometer: 49050
        )

        // Assert: Ein neuer Trip sollte existieren
        let finalTripCount = try viewContext.count(for: Trip.fetchRequest())
        XCTAssertEqual(finalTripCount, initialTripCount + 1, "createManualTrip sollte einen neuen Trip erstellen")
    }
}
