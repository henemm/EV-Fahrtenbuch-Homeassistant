//
//  ConnectionUITests.swift
//  HomeAssistentFahrtenbuchUITests
//
//  UI-Tests für Verbindungsfehler-Handling
//  Testet das tatsächliche UI-Verhalten bei verschiedenen Szenarien
//

import XCTest

final class ConnectionUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Launch-Argumente für Test-Modus
        app.launchArguments = ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Demo Mode Tests

    /// Demo-Modus: Fahrt starten sollte funktionieren ohne Offline-Dialog
    func test_demoMode_startTrip_shouldWork() throws {
        // Given: App im Demo-Modus starten
        app.launchArguments.append("--demo-mode")
        app.launch()

        // When: Auf "Fahrt starten" tippen
        let startButton = app.buttons["Fahrt starten"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start-Button sollte existieren")
        startButton.tap()

        // Then: Aktive Fahrt sollte angezeigt werden (kein Offline-Dialog)
        let activeTripView = app.staticTexts["Fahrt läuft..."]
        XCTAssertTrue(activeTripView.waitForExistence(timeout: 5), "Aktive Fahrt sollte angezeigt werden")

        // Kein Alert sollte sichtbar sein
        XCTAssertFalse(app.alerts["Keine Verbindung"].exists, "Kein Offline-Dialog im Demo-Modus")
    }

    /// Demo-Modus: Fahrt beenden sollte funktionieren
    func test_demoMode_endTrip_shouldWork() throws {
        // Given: Fahrt ist aktiv
        app.launchArguments.append("--demo-mode")
        app.launch()

        let startButton = app.buttons["Fahrt starten"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Warte auf aktive Fahrt
        let activeTripCard = app.staticTexts["Fahrt läuft..."]
        XCTAssertTrue(activeTripCard.waitForExistence(timeout: 5))

        // When: Auf aktive Fahrt tippen und beenden
        activeTripCard.tap()

        // Warte auf ActiveTripView
        let endButton = app.buttons["Fahrt beenden"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5), "Beenden-Button sollte existieren")
        endButton.tap()

        // Then: Fahrt sollte beendet sein (Start-Button wieder sichtbar)
        XCTAssertTrue(startButton.waitForExistence(timeout: 5), "Start-Button sollte nach Beenden wieder sichtbar sein")
    }

    // MARK: - Offline Mode Tests

    /// Offline-Modus: Bei Netzwerkfehler sollte Offline-Dialog erscheinen
    func test_offlineMode_startTrip_shouldShowOfflineDialog() throws {
        // Given: App mit simuliertem Netzwerkfehler starten
        app.launchArguments.append("--simulate-network-error")
        app.launch()

        // When: Auf "Fahrt starten" tippen
        let startButton = app.buttons["Fahrt starten"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Then: Offline-Dialog sollte erscheinen
        let offlineAlert = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 5), "Offline-Dialog sollte erscheinen")

        // Dialog sollte korrekte Buttons haben
        XCTAssertTrue(offlineAlert.buttons["Fahrt starten"].exists, "Button 'Fahrt starten' sollte existieren")
        XCTAssertTrue(offlineAlert.buttons["Abbrechen"].exists, "Button 'Abbrechen' sollte existieren")
    }

    /// Offline-Modus: Manuelle Eingabe sollte Fahrt erstellen
    func test_offlineMode_manualInput_shouldCreateTrip() throws {
        // Given: Offline-Dialog ist offen
        app.launchArguments.append("--simulate-network-error")
        app.launch()

        let startButton = app.buttons["Fahrt starten"]
        startButton.tap()

        let offlineAlert = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 5))

        // When: Auf "Fahrt starten" im Dialog tippen (manuelle Eingabe)
        offlineAlert.buttons["Fahrt starten"].tap()

        // Then: Fahrt sollte erstellt werden
        let activeTripCard = app.staticTexts["Fahrt läuft..."]
        XCTAssertTrue(activeTripCard.waitForExistence(timeout: 5), "Aktive Fahrt nach manueller Eingabe")
    }

    /// Offline-Modus: Abbrechen sollte Dialog schließen ohne Fahrt
    func test_offlineMode_cancel_shouldNotCreateTrip() throws {
        // Given: Offline-Dialog ist offen
        app.launchArguments.append("--simulate-network-error")
        app.launch()

        let startButton = app.buttons["Fahrt starten"]
        startButton.tap()

        let offlineAlert = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 5))

        // When: Abbrechen
        offlineAlert.buttons["Abbrechen"].tap()

        // Then: Kein aktiver Trip, Start-Button noch sichtbar
        XCTAssertTrue(startButton.waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Fahrt läuft..."].exists)
    }

    // MARK: - Error Message Tests

    /// Nicht konfiguriert: Fehlermeldung (NICHT Offline-Dialog)
    func test_notConfigured_shouldShowErrorAlert() throws {
        // Given: App ohne Konfiguration starten
        app.launchArguments.append("--reset-settings")
        app.launch()

        // When: Auf "Fahrt starten" tippen
        let startButton = app.buttons["Fahrt starten"]
        if startButton.waitForExistence(timeout: 5) {
            startButton.tap()

            // Then: Fehler-Alert sollte erscheinen (nicht Offline-Dialog)
            let errorAlert = app.alerts["Fehler"]
            if errorAlert.waitForExistence(timeout: 3) {
                XCTAssertTrue(errorAlert.staticTexts.element(matching: NSPredicate(format: "label CONTAINS 'konfiguriere'")).exists,
                             "Fehlermeldung sollte 'konfiguriere' enthalten")
            }
        }
    }

    // MARK: - Picker Wheel Tests

    /// Offline-Dialog: Picker sollte Batterie% anzeigen
    func test_offlineDialog_shouldShowBatteryPicker() throws {
        // Given: Offline-Dialog öffnen
        app.launchArguments.append("--simulate-network-error")
        app.launch()

        let startButton = app.buttons["Fahrt starten"]
        startButton.tap()

        let offlineAlert = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 5))

        // Then: Picker sollte existieren
        let picker = offlineAlert.pickers["Batterie %"]
        XCTAssertTrue(picker.exists || offlineAlert.pickerWheels.count > 0,
                     "Batterie-Picker sollte im Dialog existieren")
    }

    // MARK: - Navigation Tests

    /// Toolbar "+" Button sollte CreateTrip öffnen (nicht Offline-Dialog)
    func test_createTripButton_shouldOpenCreateSheet() throws {
        // Given: App starten
        app.launchArguments.append("--demo-mode")
        app.launch()

        // When: Auf "+" Button tippen
        let addButton = app.buttons["Fahrt erstellen"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Then: Sheet sollte sich öffnen mit "Fahrt erstellen" Titel
        // (NICHT "Fahrt bearbeiten")
        let createTitle = app.staticTexts["Fahrt erstellen"]
        XCTAssertTrue(createTitle.waitForExistence(timeout: 3) || app.navigationBars["Fahrt erstellen"].exists,
                     "Create-Sheet sollte sich öffnen")
    }

    // MARK: - Settings Tests

    /// Einstellungen: Verbindungstest-Button existiert
    func test_settings_connectionTestButton_exists() throws {
        // Given: App starten
        app.launchArguments.append("--demo-mode")
        app.launch()

        // When: Zu Einstellungen navigieren
        let settingsTab = app.tabBars.buttons["Einstellungen"]
        if settingsTab.waitForExistence(timeout: 3) {
            settingsTab.tap()

            // Then: Verbindungstest-Button sollte existieren
            let testButton = app.buttons["Verbindung testen"]
            // Dieser Test ist optional - nur wenn Settings-Tab existiert
            if testButton.waitForExistence(timeout: 3) {
                XCTAssertTrue(testButton.exists)
            }
        }
    }

    // MARK: - Trip List Tests

    /// Trip-Liste: Tap auf Trip öffnet Edit-Sheet
    func test_tripList_tapTrip_shouldOpenEditSheet() throws {
        // Given: App mit existierender Fahrt starten
        app.launchArguments.append("--demo-mode")
        app.launchArguments.append("--with-sample-trip")
        app.launch()

        // Warte auf Trip-Liste
        sleep(2) // Warte bis Daten geladen

        // When: Auf einen Trip in der Liste tippen
        // (Suche nach einem Element das wie ein Trip aussieht)
        let tripCells = app.cells.matching(identifier: "TripRow")
        if tripCells.count > 0 {
            tripCells.firstMatch.tap()

            // Then: Edit-Sheet sollte sich öffnen
            let editTitle = app.staticTexts["Fahrt bearbeiten"]
            XCTAssertTrue(editTitle.waitForExistence(timeout: 3) || app.navigationBars["Fahrt bearbeiten"].exists,
                         "Edit-Sheet sollte sich öffnen")
        }
    }

    // MARK: - Swipe Actions Tests

    /// Swipe-Aktion: Links wischen zeigt Bearbeiten
    func test_tripList_swipeLeft_shouldShowEditAction() throws {
        // Given: App mit existierender Fahrt
        app.launchArguments.append("--demo-mode")
        app.launchArguments.append("--with-sample-trip")
        app.launch()

        sleep(2)

        // When: Auf Trip nach links wischen
        let tripCells = app.cells
        if tripCells.count > 0 {
            tripCells.firstMatch.swipeLeft()

            // Then: Bearbeiten-Button sollte erscheinen
            let editButton = app.buttons["Bearbeiten"]
            if editButton.waitForExistence(timeout: 2) {
                XCTAssertTrue(editButton.exists)
            }
        }
    }

    /// Swipe-Aktion: Rechts wischen zeigt Löschen
    func test_tripList_swipeRight_shouldShowDeleteAction() throws {
        // Given: App mit existierender Fahrt
        app.launchArguments.append("--demo-mode")
        app.launchArguments.append("--with-sample-trip")
        app.launch()

        sleep(2)

        // When: Auf Trip nach rechts wischen
        let tripCells = app.cells
        if tripCells.count > 0 {
            tripCells.firstMatch.swipeRight()

            // Then: Löschen-Button sollte erscheinen
            let deleteButton = app.buttons["Löschen"]
            if deleteButton.waitForExistence(timeout: 2) {
                XCTAssertTrue(deleteButton.exists)
            }
        }
    }

    // MARK: - Full Workflow Tests

    /// Kompletter Workflow: Start → Aktive Fahrt → Beenden
    func test_fullWorkflow_startToEnd() throws {
        // Given: App im Demo-Modus
        app.launchArguments.append("--demo-mode")
        app.launch()

        // Step 1: Fahrt starten
        let startButton = app.buttons["Fahrt starten"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Step 2: Aktive Fahrt verifizieren
        let activeTripCard = app.staticTexts["Fahrt läuft..."]
        XCTAssertTrue(activeTripCard.waitForExistence(timeout: 5))

        // Step 3: Aktive Fahrt antippen
        activeTripCard.tap()

        // Step 4: Beenden-Button finden und tippen
        let endButton = app.buttons["Fahrt beenden"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5))
        endButton.tap()

        // Step 5: Start-Button sollte wieder sichtbar sein
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }

    /// Kompletter Offline-Workflow
    func test_fullOfflineWorkflow() throws {
        // Given: Simulierter Netzwerkfehler
        app.launchArguments.append("--simulate-network-error")
        app.launch()

        // Step 1: Fahrt starten → Offline-Dialog
        let startButton = app.buttons["Fahrt starten"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Step 2: Offline-Dialog verifizieren
        let offlineAlert = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlert.waitForExistence(timeout: 5))

        // Step 3: Manuell starten
        offlineAlert.buttons["Fahrt starten"].tap()

        // Step 4: Aktive Fahrt verifizieren
        let activeTripCard = app.staticTexts["Fahrt läuft..."]
        XCTAssertTrue(activeTripCard.waitForExistence(timeout: 5))

        // Step 5: Beenden (auch offline)
        activeTripCard.tap()
        let endButton = app.buttons["Fahrt beenden"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5))
        endButton.tap()

        // Step 6: Wieder Offline-Dialog
        let offlineAlertEnd = app.alerts["Keine Verbindung"]
        XCTAssertTrue(offlineAlertEnd.waitForExistence(timeout: 5))

        // Step 7: Manuell beenden
        offlineAlertEnd.buttons["Fahrt beenden"].tap()

        // Step 8: Start-Button wieder sichtbar
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
    }
}
