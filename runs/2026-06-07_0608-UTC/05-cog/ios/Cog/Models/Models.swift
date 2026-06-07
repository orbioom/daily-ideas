import Foundation
import SwiftData

/// A bicycle with an odometer that rides accumulate onto. Distances are stored
/// internally in kilometres; the UI converts for display.
@Model
final class Bike {
    var id: UUID = UUID()
    var name: String = ""
    var kind: String = "Road"
    var odometerKm: Double = 0
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Component.bike)
    var components: [Component] = []
    @Relationship(deleteRule: .cascade, inverse: \Ride.bike)
    var rides: [Ride] = []
    @Relationship(deleteRule: .cascade, inverse: \ServiceRecord.bike)
    var services: [ServiceRecord] = []

    init(name: String, kind: String = "Road", odometerKm: Double = 0) {
        self.id = UUID()
        self.name = name
        self.kind = kind
        self.odometerKm = odometerKm
        self.createdAt = Date()
    }

    var activeComponents: [Component] { components.filter { !$0.retired }.sorted { $0.name < $1.name } }

    /// Average daily distance (km) from logged rides, used for projections.
    var dailyKm: Double {
        let rs = rides.sorted { $0.date < $1.date }
        guard let first = rs.first?.date else { return 0 }
        let days = max(1, Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 1)
        let total = rs.map { $0.distanceKm }.reduce(0, +)
        return total / Double(days)
    }
}

/// A wear-tracked part on a bike (chain, tyres, brake pads…).
@Model
final class Component {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = "Drivetrain"
    var installedAtKm: Double = 0
    var installedDate: Date = Date()
    /// Expected service life in kilometres (0 = not distance-tracked).
    var lifespanKm: Double = 0
    /// Expected service life in days (0 = not time-tracked).
    var lifespanDays: Int = 0
    var retired: Bool = false
    var notes: String = ""
    var bike: Bike?

    init(name: String, category: String = "Drivetrain", installedAtKm: Double,
         lifespanKm: Double = 0, lifespanDays: Int = 0, installedDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.installedAtKm = installedAtKm
        self.installedDate = installedDate
        self.lifespanKm = lifespanKm
        self.lifespanDays = lifespanDays
    }

    var distanceUsedKm: Double { max(0, (bike?.odometerKm ?? installedAtKm) - installedAtKm) }
    var distanceRemainingKm: Double { max(0, lifespanKm - distanceUsedKm) }
    var daysUsed: Int { max(0, Calendar.current.dateComponents([.day], from: installedDate, to: Date()).day ?? 0) }

    var distanceWear: Double { lifespanKm > 0 ? distanceUsedKm / lifespanKm : 0 }
    var timeWear: Double { lifespanDays > 0 ? Double(daysUsed) / Double(lifespanDays) : 0 }
    /// Overall wear is the more advanced of the two tracked dimensions.
    var wear: Double { max(distanceWear, timeWear) }
}

/// A logged ride that adds distance to its bike's odometer.
@Model
final class Ride {
    var id: UUID = UUID()
    var date: Date = Date()
    var distanceKm: Double = 0
    var note: String = ""
    var bike: Bike?

    init(date: Date, distanceKm: Double, note: String = "") {
        self.id = UUID()
        self.date = date
        self.distanceKm = max(0, distanceKm)
        self.note = note
    }
}

/// A maintenance event in the service history.
@Model
final class ServiceRecord {
    var id: UUID = UUID()
    var date: Date = Date()
    var componentName: String = ""
    var action: String = "Replaced"      // Replaced / Serviced / Adjusted / Cleaned
    var atKm: Double = 0
    var cost: Double = 0
    var notes: String = ""
    var bike: Bike?

    init(date: Date, componentName: String, action: String, atKm: Double, cost: Double = 0, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.componentName = componentName
        self.action = action
        self.atKm = atKm
        self.cost = cost
        self.notes = notes
    }
}
