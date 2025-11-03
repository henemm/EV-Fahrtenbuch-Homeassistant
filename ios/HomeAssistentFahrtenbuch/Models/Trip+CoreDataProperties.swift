//
//  Trip+CoreDataProperties.swift
//  HomeAssistent Fahrtenbuch
//
//  Core Data Properties
//

import Foundation
import CoreData

extension Trip {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var startBatteryPercent: Double
    @NSManaged public var endBatteryPercent: Double
    @NSManaged public var startOdometer: Double
    @NSManaged public var endOdometer: Double
}

extension Trip: Identifiable {}
