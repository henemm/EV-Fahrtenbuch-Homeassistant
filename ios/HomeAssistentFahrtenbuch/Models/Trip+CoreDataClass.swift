//
//  Trip+CoreDataClass.swift
//  HomeAssistent Fahrtenbuch
//
//  Core Data Entity - Trip
//

import Foundation
import CoreData

public class Trip: NSManagedObject {

    // MARK: - Computed Properties

    /// Ist die Fahrt aktuell aktiv?
    var isActive: Bool {
        endDate == nil
    }

    /// Gefahrene Strecke in km
    var distance: Double {
        guard endOdometer > 0 else { return 0 }
        return max(0, endOdometer - startOdometer)
    }

    /// Batterieverbrauch in %
    var batteryUsed: Double {
        guard endBatteryPercent > 0 else { return 0 }
        return max(0, startBatteryPercent - endBatteryPercent)
    }

    /// Verbrauch in kWh (optional, für Info)
    func kwhUsed(batteryCapacity: Double = 77.0) -> Double {
        (batteryUsed / 100.0) * batteryCapacity
    }

    /// Kosten in € (basierend auf Batterie-Prozent)
    func cost(costPerPercent: Double) -> Double {
        batteryUsed * costPerPercent
    }

    /// Durchschnittsverbrauch in kWh/100km (optional, für Info)
    var averageConsumption: Double {
        guard distance > 0 else { return 0 }
        return (kwhUsed() / distance) * 100
    }

    /// Kosten-Info: Preis pro Prozent für diese Fahrt
    @MainActor
    func costInfo(settings: AppSettings) -> (costPerPercent: Double, season: String) {
        guard let date = startDate else {
            return (settings.costPerPercentSummer, "Sommer")
        }
        let month = Calendar.current.component(.month, from: date)
        if month < 4 || month > 10 {
            return (settings.costPerPercentWinter, "Winter")
        } else {
            return (settings.costPerPercentSummer, "Sommer")
        }
    }

    /// Dauer der Fahrt in Minuten
    var durationMinutes: Int {
        guard let start = startDate else { return 0 }

        if let end = endDate {
            return Int(end.timeIntervalSince(start) / 60)
        } else {
            // Läuft noch → seit Start
            return Int(Date().timeIntervalSince(start) / 60)
        }
    }

    /// Formatierte Dauer (z.B. "1h 23min")
    var durationFormatted: String {
        let hours = durationMinutes / 60
        let minutes = durationMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }

    // MARK: - Date Helpers

    /// Monat als String (z.B. "November 2025")
    var monthString: String {
        guard let date = startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    /// Datum als String (z.B. "2. Nov, 10:30")
    var startDateFormatted: String {
        guard let date = startDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM, HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: date)
    }

    /// End-Datum als String (z.B. "11:45")
    var endDateFormatted: String? {
        guard let end = endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "de_DE")
        return formatter.string(from: end)
    }
}
