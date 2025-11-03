//
//  ExportService.swift
//  HomeAssistent Fahrtenbuch
//
//  Export-Service für Monatsabrechnungen
//

import Foundation

@MainActor
class ExportService {

    static let shared = ExportService()

    private init() {}

    // MARK: - CSV Export

    /// Erstellt CSV-String für Monatsabrechnung
    func generateCSV(for trips: [Trip], settings: AppSettings) -> String {
        var csv = "Datum,Start Zeit,Ende Zeit,Dauer,Batterie Start,Batterie Ende,Verbrauch %,Strecke km,Tarif,Kosten EUR\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for trip in trips {
            guard let startDate = trip.startDate else { continue }

            let date = dateFormatter.string(from: startDate)
            let startTime = timeFormatter.string(from: startDate)
            let endTime = trip.endDateFormatted ?? "läuft"
            let duration = trip.durationFormatted
            let batteryStart = String(format: "%.0f", trip.startBatteryPercent)
            let batteryEnd = String(format: "%.0f", trip.endBatteryPercent)
            let batteryUsed = String(format: "%.1f", trip.batteryUsed)
            let distance = String(format: "%.1f", trip.distance)

            let costPerPercent = settings.costPerPercent(for: startDate)
            let tarif = String(format: "%.2f", costPerPercent)
            let cost = String(format: "%.2f", trip.cost(costPerPercent: costPerPercent))

            csv += "\(date),\(startTime),\(endTime),\(duration),\(batteryStart),\(batteryEnd),\(batteryUsed),\(distance),\(tarif),\(cost)\n"
        }

        return csv
    }

    /// Erstellt Abrechnungs-Text für den Monat
    func generateMonthlyReport(for trips: [Trip], settings: AppSettings, summary: TripsViewModel.MonthlySummary) -> String {
        guard let firstTrip = trips.first,
              let startDate = firstTrip.startDate else {
            return "Keine Fahrten vorhanden"
        }

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMMM yyyy"
        monthFormatter.locale = Locale(identifier: "de_DE")
        let monthString = monthFormatter.string(from: startDate)

        var report = """
        📊 Monatsabrechnung \(monthString)
        ═══════════════════════════════════

        Fahrzeug: \(settings.vehicleName)

        """

        // Fahrten-Details
        report += "Fahrten:\n"
        report += "────────────────────────────────\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM. HH:mm"

        for (index, trip) in trips.enumerated() {
            guard let tripDate = trip.startDate else { continue }

            let date = dateFormatter.string(from: tripDate)
            let batteryUsed = String(format: "%.1f%%", trip.batteryUsed)
            let distance = String(format: "%.0f km", trip.distance)
            let costPerPercent = settings.costPerPercent(for: tripDate)
            let cost = String(format: "%.2f €", trip.cost(costPerPercent: costPerPercent))
            let season = costPerPercent == settings.costPerPercentWinter ? "W" : "S"

            report += "\(index + 1). \(date) | \(batteryUsed) | \(distance) | \(season) | \(cost)\n"
        }

        // Zusammenfassung
        report += """

        ═══════════════════════════════════
        Zusammenfassung:

        Anzahl Fahrten: \(summary.tripCount)
        Gesamt-Verbrauch: \(String(format: "%.1f", trips.reduce(0.0) { $0 + $1.batteryUsed }))% Batterie
        Gesamt-Strecke: \(String(format: "%.0f", summary.totalDistance)) km

        ───────────────────────────────────
        GESAMT-KOSTEN: \(String(format: "%.2f", summary.totalCost)) €
        ═══════════════════════════════════

        Tarife:
        • Winter (Nov-März): \(String(format: "%.2f", settings.costPerPercentWinter)) € pro %
        • Sommer (Apr-Okt): \(String(format: "%.2f", settings.costPerPercentSummer)) € pro %

        (W = Winter-Tarif, S = Sommer-Tarif)
        """

        return report
    }

    // MARK: - Share Sheet Helpers

    /// Erstellt temporäre CSV-Datei für Sharing
    func createCSVFile(for trips: [Trip], settings: AppSettings) -> URL? {
        let csv = generateCSV(for: trips, settings: settings)

        let fileName = "Fahrtenbuch_\(Date().timeIntervalSince1970).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Fehler beim Erstellen der CSV-Datei: \(error)")
            return nil
        }
    }

    /// Erstellt temporäre Text-Datei für Abrechnung
    func createReportFile(for trips: [Trip], settings: AppSettings, summary: TripsViewModel.MonthlySummary) -> URL? {
        let report = generateMonthlyReport(for: trips, settings: settings, summary: summary)

        let fileName = "Abrechnung_\(Date().timeIntervalSince1970).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try report.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Fehler beim Erstellen der Abrechnungs-Datei: \(error)")
            return nil
        }
    }
}
