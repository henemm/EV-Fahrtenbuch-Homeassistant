//
//  ConnectionUIBehaviorTests.swift
//  HomeAssistentFahrtenbuchTests
//
//  UI-Verhaltenstests für Verbindungsfehler
//  Testet, dass bei Fehlern der richtige Dialog angezeigt wird
//

import XCTest
import CoreData
import Combine
@testable import HomeAssistentFahrtenbuch

// MARK: - Mock Behavior für Tests

enum MockBehavior {
    case success(batteryPercent: Double, odometerKm: Double)
    case networkError(Error)
    case timeout
    case authenticationFailed
    case serverError
    case intermittent(failCount: Int) // Schlägt n-mal fehl, dann Erfolg
}

/// Globaler Mock-State für Tests
@MainActor
class MockNetworkState {
    static var behavior: MockBehavior = .success(batteryPercent: 75, odometerKm: 50000)
    static var callCount = 0

    static func reset() {
        behavior = .success(batteryPercent: 75, odometerKm: 50000)
        callCount = 0
    }

    static func getVehicleData() async throws -> VehicleData {
        callCount += 1

        switch behavior {
        case .success(let battery, let odometer):
            return VehicleData(
                batteryPercent: battery,
                odometerKm: odometer,
                timestamp: Date()
            )

        case .networkError(let error):
            throw error

        case .timeout:
            throw URLError(.timedOut)

        case .authenticationFailed:
            throw HomeAssistantError.authenticationFailed

        case .serverError:
            throw HomeAssistantError.invalidResponse

        case .intermittent(let failCount):
            if callCount <= failCount {
                throw URLError(.notConnectedToInternet)
            }
            return VehicleData(
                batteryPercent: 75,
                odometerKm: 50000,
                timestamp: Date()
            )
        }
    }
}

// MARK: - Testable TripsViewModel

/// Vereinfachtes ViewModel für Tests - verwendet MockNetworkState
@MainActor
class TestableTripsViewModel: ObservableObject {

    @Published var activeTrip: Trip?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showManualInputAlert = false
    @Published var manualInputContext: ManualInputContext?

    enum ManualInputContext {
        case startTrip
        case endTrip
    }

    private let viewContext: NSManagedObjectContext
    private let settings: AppSettings

    init(
        context: NSManagedObjectContext,
        settings: AppSettings
    ) {
        self.viewContext = context
        self.settings = settings
    }

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
            let vehicleData = try await MockNetworkState.getVehicleData()

            let trip = Trip(context: viewContext)
            trip.id = UUID()
            trip.startDate = vehicleData.timestamp
            trip.startBatteryPercent = vehicleData.batteryPercent
            trip.startOdometer = vehicleData.odometerKm

            try viewContext.save()
            activeTrip = trip

        } catch {
            // Bei JEDEM Fehler: Offline-Dialog anzeigen, NICHT Fehlermeldung
            errorMessage = nil
            manualInputContext = .startTrip
            showManualInputAlert = true
        }

        isLoading = false
    }

    func endTrip() async {
        guard let trip = activeTrip else {
            errorMessage = "Keine aktive Fahrt gefunden"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let vehicleData = try await MockNetworkState.getVehicleData()

            trip.endDate = vehicleData.timestamp
            trip.endBatteryPercent = vehicleData.batteryPercent
            trip.endOdometer = vehicleData.odometerKm

            try viewContext.save()
            activeTrip = nil

        } catch {
            // Bei JEDEM Fehler: Offline-Dialog anzeigen, NICHT Fehlermeldung
            errorMessage = nil
            manualInputContext = .endTrip
            showManualInputAlert = true
        }

        isLoading = false
    }

    func startTripManually(batteryPercent: Double) {
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.startDate = Date()
        trip.startBatteryPercent = batteryPercent
        trip.startOdometer = 0

        do {
            try viewContext.save()
            activeTrip = trip
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }

    func endTripManually(batteryPercent: Double) {
        guard let trip = activeTrip else { return }

        trip.endDate = Date()
        trip.endBatteryPercent = batteryPercent
        trip.endOdometer = trip.startOdometer

        do {
            try viewContext.save()
            activeTrip = nil
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}

// MARK: - UI Behavior Tests

@MainActor
final class ConnectionUIBehaviorTests: XCTestCase {

    var viewContext: NSManagedObjectContext!
    var persistenceController: PersistenceController!
    var settings: AppSettings!
    var viewModel: TestableTripsViewModel!

    override func setUp() {
        super.setUp()

        persistenceController = PersistenceController(inMemory: true)
        viewContext = persistenceController.container.viewContext

        settings = AppSettings.shared
        settings.demoMode = false

        // Konfiguriere Settings für Tests
        settings.homeAssistantURL = "https://test.home-assistant.io"
        settings.homeAssistantToken = "test_token"
        settings.batteryEntityId = "sensor.battery"
        settings.odometerEntityId = "sensor.odometer"

        // Reset Mock-State
        MockNetworkState.reset()

        viewModel = TestableTripsViewModel(
            context: viewContext,
            settings: settings
        )
    }

    override func tearDown() {
        viewModel = nil
        settings = nil
        viewContext = nil
        persistenceController = nil
        MockNetworkState.reset()
        super.tearDown()
    }

    // MARK: - Erfolgsfall Tests

    /// Bei erfolgreicher Verbindung: Kein Alert, Fahrt wird erstellt
    func test_startTrip_success_shouldNotShowAlert() async {
        // Given
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertFalse(viewModel.showManualInputAlert, "Kein Offline-Dialog bei Erfolg")
        XCTAssertNil(viewModel.errorMessage, "Keine Fehlermeldung bei Erfolg")
        XCTAssertNotNil(viewModel.activeTrip, "Fahrt sollte erstellt werden")
        XCTAssertEqual(viewModel.activeTrip?.startBatteryPercent, 80)
    }

    /// Bei erfolgreicher Verbindung beim Beenden: Kein Alert
    func test_endTrip_success_shouldNotShowAlert() async {
        // Given: Aktive Fahrt vorhanden
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)
        await viewModel.startTrip()
        XCTAssertNotNil(viewModel.activeTrip)

        MockNetworkState.behavior = .success(batteryPercent: 60, odometerKm: 49550)

        // When
        await viewModel.endTrip()

        // Then
        XCTAssertFalse(viewModel.showManualInputAlert, "Kein Offline-Dialog bei Erfolg")
        XCTAssertNil(viewModel.errorMessage, "Keine Fehlermeldung bei Erfolg")
        XCTAssertNil(viewModel.activeTrip, "Fahrt sollte beendet sein")
    }

    // MARK: - Timeout Tests

    /// Bei Timeout: Offline-Dialog anzeigen, NICHT Fehlermeldung
    func test_startTrip_timeout_shouldShowOfflineDialog() async {
        // Given
        MockNetworkState.behavior = .timeout

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung - nur Offline-Dialog")
        XCTAssertEqual(viewModel.manualInputContext, .startTrip, "Kontext sollte startTrip sein")
        XCTAssertNil(viewModel.activeTrip, "Noch keine Fahrt erstellt")
    }

    /// Bei Timeout beim Beenden: Offline-Dialog anzeigen
    func test_endTrip_timeout_shouldShowOfflineDialog() async {
        // Given: Aktive Fahrt vorhanden
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)
        await viewModel.startTrip()

        MockNetworkState.behavior = .timeout

        // When
        await viewModel.endTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung - nur Offline-Dialog")
        XCTAssertEqual(viewModel.manualInputContext, .endTrip, "Kontext sollte endTrip sein")
    }

    // MARK: - Kein Internet Tests

    /// Bei fehlendem Internet: Offline-Dialog anzeigen
    func test_startTrip_noInternet_shouldShowOfflineDialog() async {
        // Given
        MockNetworkState.behavior = .networkError(URLError(.notConnectedToInternet))

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung bei Offline")
        XCTAssertEqual(viewModel.manualInputContext, .startTrip)
    }

    /// Bei DNS-Fehler: Offline-Dialog anzeigen
    func test_startTrip_dnsFailure_shouldShowOfflineDialog() async {
        // Given
        MockNetworkState.behavior = .networkError(URLError(.cannotFindHost))

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung")
    }

    // MARK: - Server Error Tests

    /// Bei Server-Fehler: Offline-Dialog anzeigen (NICHT Fehlermeldung!)
    func test_startTrip_serverError_shouldShowOfflineDialog_notErrorMessage() async {
        // Given
        MockNetworkState.behavior = .serverError

        // When
        await viewModel.startTrip()

        // Then: Wichtig - Offline-Dialog, NICHT Fehlermeldung!
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung - User soll Offline-Dialog sehen")
    }

    /// Bei Auth-Fehler: Offline-Dialog anzeigen (User kann trotzdem fortfahren)
    func test_startTrip_authError_shouldShowOfflineDialog() async {
        // Given
        MockNetworkState.behavior = .authenticationFailed

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog sollte angezeigt werden")
        XCTAssertNil(viewModel.errorMessage, "KEINE Fehlermeldung")
    }

    // MARK: - Manuelle Eingabe Tests

    /// Nach Offline-Dialog: Manuelle Eingabe erstellt Fahrt
    func test_startTrip_manualInput_shouldCreateTrip() async {
        // Given: Netzwerkfehler führt zu Offline-Dialog
        MockNetworkState.behavior = .timeout
        await viewModel.startTrip()
        XCTAssertTrue(viewModel.showManualInputAlert)

        // When: User gibt manuell Batterie% ein
        viewModel.startTripManually(batteryPercent: 75)

        // Then
        XCTAssertNotNil(viewModel.activeTrip, "Fahrt sollte erstellt werden")
        XCTAssertEqual(viewModel.activeTrip?.startBatteryPercent, 75)
        XCTAssertEqual(viewModel.activeTrip?.startOdometer, 0, "Odometer ist 0 bei manuellem Start")
    }

    /// Nach Offline-Dialog beim Beenden: Manuelle Eingabe beendet Fahrt
    func test_endTrip_manualInput_shouldEndTrip() async {
        // Given: Fahrt vorhanden, Netzwerkfehler beim Beenden
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)
        await viewModel.startTrip()
        XCTAssertNotNil(viewModel.activeTrip)

        MockNetworkState.behavior = .timeout
        await viewModel.endTrip()
        XCTAssertTrue(viewModel.showManualInputAlert)

        // When: User gibt manuell Batterie% ein
        viewModel.endTripManually(batteryPercent: 60)

        // Then
        XCTAssertNil(viewModel.activeTrip, "Fahrt sollte beendet sein")
    }

    // MARK: - Intermittent Connection Tests

    /// Sporadische Verbindungsprobleme: Offline-Dialog bei Fehler
    func test_startTrip_intermittentConnection_shouldShowOfflineOnFailure() async {
        // Given: Erste 2 Versuche schlagen fehl
        MockNetworkState.behavior = .intermittent(failCount: 2)

        // When: Erster Versuch
        await viewModel.startTrip()

        // Then: Offline-Dialog
        XCTAssertTrue(viewModel.showManualInputAlert, "Offline-Dialog bei erstem Fehler")
        XCTAssertNil(viewModel.activeTrip)
    }

    // MARK: - Loading State Tests

    /// Loading-State wird korrekt gesetzt
    func test_startTrip_shouldSetLoadingState() async {
        // Given
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)

        // isLoading sollte nach dem Aufruf false sein (async completed)
        XCTAssertFalse(viewModel.isLoading, "Sollte initial nicht laden")

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertFalse(viewModel.isLoading, "Sollte nach Abschluss nicht mehr laden")
    }

    // MARK: - Edge Case Tests

    /// Doppelter Start sollte Fehlermeldung zeigen (NICHT Offline-Dialog)
    func test_startTrip_alreadyActive_shouldShowErrorMessage() async {
        // Given: Fahrt bereits aktiv
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)
        await viewModel.startTrip()
        XCTAssertNotNil(viewModel.activeTrip)

        // Reset
        viewModel.errorMessage = nil
        viewModel.showManualInputAlert = false

        // When: Zweiter Start
        await viewModel.startTrip()

        // Then: Fehlermeldung, NICHT Offline-Dialog
        XCTAssertNotNil(viewModel.errorMessage, "Fehlermeldung bei doppeltem Start")
        XCTAssertEqual(viewModel.errorMessage, "Es läuft bereits eine Fahrt")
        XCTAssertFalse(viewModel.showManualInputAlert, "Kein Offline-Dialog bei doppeltem Start")
    }

    /// Beenden ohne aktive Fahrt sollte Fehlermeldung zeigen
    func test_endTrip_noActiveTrip_shouldShowErrorMessage() async {
        // Given: Keine aktive Fahrt
        XCTAssertNil(viewModel.activeTrip)

        // When
        await viewModel.endTrip()

        // Then
        XCTAssertNotNil(viewModel.errorMessage, "Fehlermeldung wenn keine Fahrt aktiv")
        XCTAssertEqual(viewModel.errorMessage, "Keine aktive Fahrt gefunden")
        XCTAssertFalse(viewModel.showManualInputAlert)
    }

    /// Nicht konfigurierte App sollte Fehlermeldung zeigen
    func test_startTrip_notConfigured_shouldShowErrorMessage() async {
        // Given: Settings nicht konfiguriert
        settings.homeAssistantURL = ""
        settings.homeAssistantToken = ""

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("konfiguriere") ?? false)
        XCTAssertFalse(viewModel.showManualInputAlert, "Kein Offline-Dialog bei fehlender Konfiguration")
    }

    // MARK: - Dialog Content Tests

    /// Offline-Dialog hat korrekten Kontext für Start
    func test_offlineDialog_startTrip_hasCorrectContext() async {
        // Given
        MockNetworkState.behavior = .timeout

        // When
        await viewModel.startTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert)
        XCTAssertEqual(viewModel.manualInputContext, .startTrip)
        // In der UI würde der Button "Fahrt starten" heißen
    }

    /// Offline-Dialog hat korrekten Kontext für Ende
    func test_offlineDialog_endTrip_hasCorrectContext() async {
        // Given
        MockNetworkState.behavior = .success(batteryPercent: 80, odometerKm: 49500)
        await viewModel.startTrip()

        MockNetworkState.behavior = .timeout

        // When
        await viewModel.endTrip()

        // Then
        XCTAssertTrue(viewModel.showManualInputAlert)
        XCTAssertEqual(viewModel.manualInputContext, .endTrip)
        // In der UI würde der Button "Fahrt beenden" heißen
    }

    // MARK: - Vollständiger Offline-Workflow Test

    /// Kompletter Offline-Workflow: Start → Manuell → Ende → Manuell
    func test_fullOfflineWorkflow() async {
        // Given: Immer offline
        MockNetworkState.behavior = .timeout

        // Step 1: Start (offline)
        await viewModel.startTrip()
        XCTAssertTrue(viewModel.showManualInputAlert)
        XCTAssertEqual(viewModel.manualInputContext, .startTrip)

        // Step 2: Manuell starten
        viewModel.showManualInputAlert = false
        viewModel.startTripManually(batteryPercent: 80)
        XCTAssertNotNil(viewModel.activeTrip)
        XCTAssertEqual(viewModel.activeTrip?.startBatteryPercent, 80)

        // Step 3: Ende (offline)
        await viewModel.endTrip()
        XCTAssertTrue(viewModel.showManualInputAlert)
        XCTAssertEqual(viewModel.manualInputContext, .endTrip)

        // Step 4: Manuell beenden
        viewModel.showManualInputAlert = false
        viewModel.endTripManually(batteryPercent: 60)
        XCTAssertNil(viewModel.activeTrip)
    }

    // MARK: - Connection Recovery Test

    /// Nach Offline-Modus: Nächster Versuch mit Verbindung funktioniert
    func test_connectionRecovery_shouldWorkNormally() async {
        // Given: Erst offline, dann online
        MockNetworkState.behavior = .timeout
        await viewModel.startTrip()
        XCTAssertTrue(viewModel.showManualInputAlert)

        // Reset
        viewModel.showManualInputAlert = false
        MockNetworkState.behavior = .success(batteryPercent: 75, odometerKm: 50000)

        // When: Erneuter Versuch mit Verbindung
        await viewModel.startTrip()

        // Then: Erfolg ohne Offline-Dialog
        XCTAssertFalse(viewModel.showManualInputAlert)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.activeTrip)
    }
}
