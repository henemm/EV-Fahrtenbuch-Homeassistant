//
//  TripDebugLogger.swift
//  HomeAssistent Fahrtenbuch
//
//  Debug-Service: Pollt API während Fahrt, loggt alle Änderungen
//

import Foundation

struct DebugLogEntry: Codable {
    let timestamp: Date
    let batteryPercent: Double
    let odometerKm: Double
    let secondsSinceStart: Int
}

@MainActor
class TripDebugLogger: ObservableObject {

    @Published var isLogging = false
    @Published var entries: [DebugLogEntry] = []

    private var pollTask: Task<Void, Never>?
    private var tripStartTime: Date?

    static let shared = TripDebugLogger()

    private init() {}

    // MARK: - Public Methods

    /// Startet Polling für aktive Fahrt
    func startLogging(haService: HomeAssistantService, settings: AppSettings) {
        guard !isLogging else { return }

        isLogging = true
        tripStartTime = Date()
        entries.removeAll()

        print("🔍 Debug-Logging gestartet - Poll alle 30s")

        pollTask = Task {
            while !Task.isCancelled {
                await pollAPI(haService: haService, settings: settings)

                // Warte 30 Sekunden
                try? await Task.sleep(nanoseconds: 30_000_000_000)
            }
        }
    }

    /// Stoppt Polling
    func stopLogging() {
        guard isLogging else { return }

        pollTask?.cancel()
        pollTask = nil
        isLogging = false
        tripStartTime = nil

        print("🔍 Debug-Logging gestoppt - \(entries.count) Einträge")
    }

    /// Exportiert Log als CSV
    func exportLog() -> URL? {
        guard !entries.isEmpty else { return nil }

        var csvContent = "Timestamp,Sekunden seit Start,Batterie %,Odometer km\n"

        for entry in entries {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestampStr = formatter.string(from: entry.timestamp)

            csvContent += "\(timestampStr),\(entry.secondsSinceStart),\(String(format: "%.1f", entry.batteryPercent)),\(String(format: "%.1f", entry.odometerKm))\n"
        }

        // Speichern im Temp-Verzeichnis
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "Debug_Log_\(Date().timeIntervalSince1970).csv"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            print("📊 Debug-Log exportiert: \(fileURL)")
            return fileURL
        } catch {
            print("❌ Export-Fehler: \(error)")
            return nil
        }
    }

    // MARK: - Private Methods

    private func pollAPI(haService: HomeAssistantService, settings: AppSettings) async {
        do {
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

            let secondsSinceStart = Int(Date().timeIntervalSince(tripStartTime ?? Date()))

            let entry = DebugLogEntry(
                timestamp: vehicleData.timestamp,
                batteryPercent: vehicleData.batteryPercent,
                odometerKm: vehicleData.odometerKm,
                secondsSinceStart: secondsSinceStart
            )

            entries.append(entry)

            // Log nur wenn Werte sich ändern (um Output sauber zu halten)
            if entries.count == 1 || hasValuesChanged() {
                print("🔍 [\(secondsSinceStart)s] Batterie: \(String(format: "%.1f", vehicleData.batteryPercent))% | Odometer: \(String(format: "%.0f", vehicleData.odometerKm)) km")
            }

        } catch {
            print("🔍 Poll-Fehler: \(error.localizedDescription)")
        }
    }

    private func hasValuesChanged() -> Bool {
        guard entries.count >= 2 else { return true }

        let last = entries[entries.count - 1]
        let previous = entries[entries.count - 2]

        return last.batteryPercent != previous.batteryPercent ||
               last.odometerKm != previous.odometerKm
    }
}
