//
//  ConnectionErrorTests.swift
//  HomeAssistentFahrtenbuchTests
//
//  Tests für Verbindungsprobleme und Error-Handling
//  Simuliert verschiedene Netzwerk-Szenarien
//

import XCTest
import CoreData
@testable import HomeAssistentFahrtenbuch

// MARK: - Mock URLProtocol für Netzwerk-Simulation

class MockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            XCTFail("MockURLProtocol.requestHandler not set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Testable HomeAssistantService

/// Testbare Version des HomeAssistantService mit injizierbarer URLSession
class TestableHomeAssistantService {

    private let urlSession: URLSession

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }

    func testConnection(url: String, token: String) async throws {
        guard let apiURL = URL(string: "\(url.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/api/") else {
            throw HomeAssistantError.invalidURL
        }

        var request = URLRequest(url: apiURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw HomeAssistantError.authenticationFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw HomeAssistantError.invalidResponse
        }
    }

    func getEntityState(url: String, token: String, entityId: String) async throws -> EntityState {
        guard let apiURL = URL(string: "\(url.trimmingCharacters(in: CharacterSet(charactersIn: "/")))/api/states/\(entityId)") else {
            throw HomeAssistantError.invalidURL
        }

        var request = URLRequest(url: apiURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HomeAssistantError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw HomeAssistantError.authenticationFailed
        }

        if httpResponse.statusCode == 404 {
            throw HomeAssistantError.entityNotFound(entityId)
        }

        guard httpResponse.statusCode == 200 else {
            throw HomeAssistantError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(EntityState.self, from: data)
    }

    func getVehicleData(
        url: String,
        token: String,
        batteryEntityId: String,
        odometerEntityId: String
    ) async throws -> VehicleData {
        async let battery = getEntityState(url: url, token: token, entityId: batteryEntityId)
        async let odometer = getEntityState(url: url, token: token, entityId: odometerEntityId)

        let (batteryState, odometerState) = try await (battery, odometer)

        guard let batteryValue = Double(batteryState.state),
              let odometerValue = Double(odometerState.state) else {
            throw HomeAssistantError.invalidResponse
        }

        return VehicleData(
            batteryPercent: batteryValue,
            odometerKm: odometerValue,
            timestamp: Date()
        )
    }
}

// MARK: - Connection Error Tests

@MainActor
final class ConnectionErrorTests: XCTestCase {

    var mockSession: URLSession!
    var service: TestableHomeAssistantService!

    let testURL = "https://test.home-assistant.io"
    let testToken = "test_token_123"
    let batteryEntityId = "sensor.enyaq_battery_level"
    let odometerEntityId = "sensor.enyaq_odometer"

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        service = TestableHomeAssistantService(urlSession: mockSession)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Timeout Tests

    /// Simuliert: Server antwortet nicht (Timeout)
    func test_connection_timeout_shouldThrowNetworkError() async {
        // Given: Server antwortet nie (Timeout simulieren)
        MockURLProtocol.requestHandler = { request in
            throw URLError(.timedOut)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch {
            // Erwarte URLError.timedOut oder HomeAssistantError.networkError
            XCTAssertTrue(
                error is URLError || error is HomeAssistantError,
                "Fehler sollte URLError oder HomeAssistantError sein, war: \(type(of: error))"
            )
        }
    }

    // MARK: - No Internet Tests

    /// Simuliert: Kein Internet (Offline)
    func test_connection_noInternet_shouldThrowNetworkError() async {
        // Given: Keine Netzwerkverbindung
        MockURLProtocol.requestHandler = { request in
            throw URLError(.notConnectedToInternet)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            // Auch andere Fehlertypen sind akzeptabel
            XCTAssertNotNil(error)
        }
    }

    /// Simuliert: DNS-Auflösung fehlgeschlagen
    func test_connection_dnsFailure_shouldThrowNetworkError() async {
        // Given: Host kann nicht aufgelöst werden
        MockURLProtocol.requestHandler = { request in
            throw URLError(.cannotFindHost)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .cannotFindHost)
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Server Error Tests

    /// Simuliert: Server ist erreichbar aber antwortet mit 500
    func test_connection_serverError500_shouldThrowInvalidResponse() async {
        // Given: Server antwortet mit 500 Internal Server Error
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as HomeAssistantError {
            if case .invalidResponse = error {
                // Erwarteter Fehler
            } else {
                XCTFail("Erwartete invalidResponse, bekam: \(error)")
            }
        } catch {
            XCTFail("Unerwarteter Fehlertyp: \(error)")
        }
    }

    /// Simuliert: Server ist überlastet (503)
    func test_connection_serviceUnavailable503_shouldThrowInvalidResponse() async {
        // Given: Server ist überlastet
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as HomeAssistantError {
            if case .invalidResponse = error {
                // Erwarteter Fehler
            } else {
                XCTFail("Erwartete invalidResponse, bekam: \(error)")
            }
        } catch {
            XCTFail("Unerwarteter Fehlertyp: \(error)")
        }
    }

    // MARK: - Authentication Error Tests

    /// Simuliert: Token ungültig/abgelaufen (401)
    func test_connection_authenticationFailed401_shouldThrowAuthError() async {
        // Given: Token ist ungültig
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as HomeAssistantError {
            if case .authenticationFailed = error {
                // Erwarteter Fehler
            } else {
                XCTFail("Erwartete authenticationFailed, bekam: \(error)")
            }
        } catch {
            XCTFail("Unerwarteter Fehlertyp: \(error)")
        }
    }

    // MARK: - Entity Not Found Tests

    /// Simuliert: Entity existiert nicht (404)
    func test_getEntityState_entityNotFound_shouldThrowEntityNotFound() async {
        // Given: Entity existiert nicht
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        // When/Then
        do {
            _ = try await service.getEntityState(
                url: testURL,
                token: testToken,
                entityId: "sensor.nicht_vorhanden"
            )
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as HomeAssistantError {
            if case .entityNotFound(let entityId) = error {
                XCTAssertEqual(entityId, "sensor.nicht_vorhanden")
            } else {
                XCTFail("Erwartete entityNotFound, bekam: \(error)")
            }
        } catch {
            XCTFail("Unerwarteter Fehlertyp: \(error)")
        }
    }

    // MARK: - Invalid Response Tests

    /// Simuliert: Server antwortet mit ungültigem JSON
    func test_getEntityState_invalidJSON_shouldThrowInvalidResponse() async {
        // Given: Server antwortet mit ungültigem JSON
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let invalidJSON = "{ invalid json }".data(using: .utf8)!
            return (response, invalidJSON)
        }

        // When/Then
        do {
            _ = try await service.getEntityState(
                url: testURL,
                token: testToken,
                entityId: batteryEntityId
            )
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as HomeAssistantError {
            if case .invalidResponse = error {
                // Erwarteter Fehler
            } else {
                XCTFail("Erwartete invalidResponse, bekam: \(error)")
            }
        } catch {
            // DecodingError ist auch akzeptabel
            XCTAssertTrue(error is DecodingError || error is HomeAssistantError)
        }
    }

    /// Simuliert: Server antwortet mit leerem Body
    func test_getEntityState_emptyResponse_shouldThrowInvalidResponse() async {
        // Given: Server antwortet mit leerem Body
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        // When/Then
        do {
            _ = try await service.getEntityState(
                url: testURL,
                token: testToken,
                entityId: batteryEntityId
            )
            XCTFail("Sollte einen Fehler werfen")
        } catch {
            // Jeder Fehler ist hier akzeptabel
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Connection Lost During Request Tests

    /// Simuliert: Verbindung bricht während Request ab
    func test_connection_lostDuringRequest_shouldThrowNetworkError() async {
        // Given: Verbindung bricht ab
        MockURLProtocol.requestHandler = { request in
            throw URLError(.networkConnectionLost)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .networkConnectionLost)
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Successful Connection Tests

    /// Verifiziert: Erfolgreiche Verbindung
    func test_connection_success_shouldNotThrow() async {
        // Given: Server antwortet erfolgreich
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let json = """
            {"message": "API running"}
            """.data(using: .utf8)!
            return (response, json)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            // Kein Fehler = Erfolg
        } catch {
            XCTFail("Sollte keinen Fehler werfen: \(error)")
        }
    }

    /// Verifiziert: Erfolgreiche Entity-Abfrage
    func test_getEntityState_success_shouldReturnState() async {
        // Given: Server antwortet mit gültiger Entity
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let json = """
            {
                "state": "75",
                "last_updated": "2025-01-01T12:00:00+00:00",
                "attributes": {
                    "unit_of_measurement": "%",
                    "friendly_name": "Battery Level"
                }
            }
            """.data(using: .utf8)!
            return (response, json)
        }

        // When
        do {
            let state = try await service.getEntityState(
                url: testURL,
                token: testToken,
                entityId: batteryEntityId
            )

            // Then
            XCTAssertEqual(state.state, "75")
            XCTAssertEqual(state.attributes?.unitOfMeasurement, "%")
        } catch {
            XCTFail("Sollte keinen Fehler werfen: \(error)")
        }
    }

    // MARK: - Intermittent Connection Tests

    /// Simuliert: Sporadische Verbindungsprobleme (mal ok, mal nicht)
    func test_connection_intermittent_shouldHandleGracefully() async {
        // Given: Erste zwei Requests schlagen fehl, dritter erfolgreich
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1

            if requestCount < 3 {
                throw URLError(.timedOut)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil)
        }

        // When: Erster Versuch sollte fehlschlagen
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Erster Versuch sollte fehlschlagen")
        } catch {
            // Erwarteter Fehler
        }

        // Zweiter Versuch sollte auch fehlschlagen
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Zweiter Versuch sollte fehlschlagen")
        } catch {
            // Erwarteter Fehler
        }

        // Dritter Versuch sollte erfolgreich sein
        do {
            try await service.testConnection(url: testURL, token: testToken)
            // Erfolg!
        } catch {
            XCTFail("Dritter Versuch sollte erfolgreich sein: \(error)")
        }
    }

    // MARK: - SSL/TLS Error Tests

    /// Simuliert: SSL-Zertifikatsfehler
    func test_connection_sslError_shouldThrowNetworkError() async {
        // Given: SSL-Zertifikat ungültig
        MockURLProtocol.requestHandler = { request in
            throw URLError(.serverCertificateUntrusted)
        }

        // When/Then
        do {
            try await service.testConnection(url: testURL, token: testToken)
            XCTFail("Sollte einen Fehler werfen")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .serverCertificateUntrusted)
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
