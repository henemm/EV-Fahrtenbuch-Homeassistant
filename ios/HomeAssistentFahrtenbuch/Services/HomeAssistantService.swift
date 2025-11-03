//
//  HomeAssistantService.swift
//  HomeAssistent Fahrtenbuch
//
//  API-Client für Home Assistant REST API
//  Basierend auf dem validierten Python-Prototyp
//

import Foundation

// MARK: - Models

struct VehicleData {
    let batteryPercent: Double
    let odometerKm: Double
    let timestamp: Date
}

enum HomeAssistantError: LocalizedError {
    case invalidURL
    case noToken
    case networkError(Error)
    case invalidResponse
    case entityNotFound(String)
    case authenticationFailed
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige Home Assistant URL"
        case .noToken:
            return "Kein Token konfiguriert"
        case .networkError(let error):
            return "Netzwerkfehler: \(error.localizedDescription)"
        case .invalidResponse:
            return "Ungültige Antwort vom Server"
        case .entityNotFound(let entityId):
            return "Entity nicht gefunden: \(entityId)"
        case .authenticationFailed:
            return "Authentifizierung fehlgeschlagen. Prüfe Token."
        case .unknownError:
            return "Unbekannter Fehler"
        }
    }
}

// MARK: - Service

@MainActor
class HomeAssistantService {

    static let shared = HomeAssistantService()

    private let urlSession: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// Testet Verbindung zu Home Assistant
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

    /// Liest aktuellen State einer Entity
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

        do {
            return try decoder.decode(EntityState.self, from: data)
        } catch {
            throw HomeAssistantError.invalidResponse
        }
    }

    /// Liest alle relevanten Fahrzeugdaten (Batterie + Odometer)
    func getVehicleData(
        url: String,
        token: String,
        batteryEntityId: String,
        odometerEntityId: String
    ) async throws -> VehicleData {
        // Parallel abrufen für bessere Performance
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

    // MARK: - Demo Mode

    /// Liefert simulierte Fahrzeugdaten (für App Store Review / Testing)
    func getDemoVehicleData() async -> VehicleData {
        // Simuliere Netzwerk-Delay
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 Sekunden

        // Realistische Demo-Werte
        let baseBattery = 70.0
        let baseOdometer = 49230.0

        // Zufällige Variation (für mehrere Demo-Fahrten)
        let batteryVariation = Double.random(in: -5...5)
        let odometerVariation = Double.random(in: 0...100)

        return VehicleData(
            batteryPercent: baseBattery + batteryVariation,
            odometerKm: baseOdometer + odometerVariation,
            timestamp: Date()
        )
    }
}

// MARK: - Entity Response Model

struct EntityState: Codable {
    let state: String
    let lastUpdated: Date
    let attributes: EntityAttributes?

    enum CodingKeys: String, CodingKey {
        case state
        case lastUpdated = "last_updated"
        case attributes
    }
}

struct EntityAttributes: Codable {
    let unitOfMeasurement: String?
    let friendlyName: String?

    enum CodingKeys: String, CodingKey {
        case unitOfMeasurement = "unit_of_measurement"
        case friendlyName = "friendly_name"
    }
}
