//
//  PersistenceController.swift
//  HomeAssistent Fahrtenbuch
//
//  Core Data Stack Manager
//

import CoreData

struct PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // MARK: - Preview (für SwiftUI Previews)

    nonisolated(unsafe) static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Erstelle Test-Daten für Previews
        for i in 0..<10 {
            let trip = Trip(context: viewContext)
            trip.id = UUID()
            let startDate = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            trip.startDate = startDate
            trip.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)
            trip.startBatteryPercent = 80.0
            trip.endBatteryPercent = 65.0
            trip.startOdometer = 49000.0 + Double(i * 50)
            trip.endOdometer = trip.startOdometer + 45.0
        }

        do {
            try viewContext.save()
        } catch {
            fatalError("Preview-Daten konnten nicht erstellt werden: \(error)")
        }

        return controller
    }()

    // MARK: - Init

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Fahrtenbuch")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data Load Error: \(error)")
                print("Description: \(description)")
                fatalError("Core Data Store konnte nicht geladen werden: \(error)")
            }
            print("✅ Core Data Store geladen: \(description.url?.absoluteString ?? "unknown")")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }

    // MARK: - Save

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data Save Error: \(error)")
            }
        }
    }

    // MARK: - Fetch Requests

    /// Fetch-Request für alle abgeschlossenen Fahrten (neueste zuerst)
    static func fetchCompletedTrips() -> NSFetchRequest<Trip> {
        let request = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "endDate != nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        return request
    }

    /// Fetch-Request für aktive Fahrt (läuft gerade)
    static func fetchActiveTrip() -> NSFetchRequest<Trip> {
        let request = Trip.fetchRequest()
        request.predicate = NSPredicate(format: "endDate == nil")
        request.fetchLimit = 1
        return request
    }

    /// Fetch-Request für Fahrten eines bestimmten Monats
    static func fetchTrips(for month: Date) -> NSFetchRequest<Trip> {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return Trip.fetchRequest()
        }

        let request = Trip.fetchRequest()
        request.predicate = NSPredicate(
            format: "startDate >= %@ AND startDate < %@",
            startOfMonth as NSDate,
            endOfMonth as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Trip.startDate, ascending: false)]
        return request
    }

    // MARK: - Delete All (für Reset)

    func deleteAllTrips() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Trip.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try container.viewContext.execute(deleteRequest)
            try container.viewContext.save()
        } catch {
            print("Fehler beim Löschen aller Fahrten: \(error)")
        }
    }
}
