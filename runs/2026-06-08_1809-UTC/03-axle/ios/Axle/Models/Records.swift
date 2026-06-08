import Foundation
import SwiftUI
import SwiftData

/// A refueling event. `liters` and `odometerKm` are canonical; `totalCost` is
/// in the user's currency. `isFullTank` enables partial-fill-aware economy.
@Model
final class FuelEntry {
    var date: Date
    var odometerKm: Double
    var liters: Double
    var totalCost: Double
    var isFullTank: Bool
    var vehicle: Vehicle?

    init(date: Date = .now,
         odometerKm: Double,
         liters: Double,
         totalCost: Double,
         isFullTank: Bool = true) {
        self.date = date
        self.odometerKm = max(0, odometerKm)
        self.liters = max(0, liters)
        self.totalCost = max(0, totalCost)
        self.isFullTank = isFullTank
    }

    var pricePerLiter: Double { liters > 0 ? totalCost / liters : 0 }
}

@Model
final class ServiceRecord {
    var date: Date
    var odometerKm: Double
    var typeRaw: String
    var cost: Double
    var notes: String
    var vehicle: Vehicle?

    init(date: Date = .now,
         odometerKm: Double,
         type: ServiceType = .oilChange,
         cost: Double = 0,
         notes: String = "") {
        self.date = date
        self.odometerKm = max(0, odometerKm)
        self.typeRaw = type.rawValue
        self.cost = max(0, cost)
        self.notes = notes
    }

    var type: ServiceType {
        get { ServiceType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}

enum ServiceType: String, CaseIterable, Identifiable, Codable {
    case oilChange, tires, brakes, battery, filters, inspection
    case fluids, wipers, spark, transmission, registration, insurance, repair, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oilChange: return "Oil change"
        case .tires: return "Tires"
        case .brakes: return "Brakes"
        case .battery: return "Battery"
        case .filters: return "Filters"
        case .inspection: return "Inspection"
        case .fluids: return "Fluids"
        case .wipers: return "Wipers"
        case .spark: return "Spark plugs"
        case .transmission: return "Transmission"
        case .registration: return "Registration"
        case .insurance: return "Insurance"
        case .repair: return "Repair"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .oilChange: return "drop.fill"
        case .tires: return "circle.circle"
        case .brakes: return "octagon"
        case .battery: return "minus.plus.batteryblock"
        case .filters: return "air.purifier"
        case .inspection: return "checkmark.seal"
        case .fluids: return "drop.triangle"
        case .wipers: return "windshield.front.and.wiper"
        case .spark: return "bolt.fill"
        case .transmission: return "gearshape.2"
        case .registration: return "doc.text"
        case .insurance: return "shield"
        case .repair: return "wrench.and.screwdriver"
        case .other: return "ellipsis.circle"
        }
    }
}

/// A maintenance reminder, due by distance, date, or both. Repeating reminders
/// roll forward when marked done.
@Model
final class ServiceReminder {
    var title: String
    var typeRaw: String
    var dueOdometerKm: Double      // 0 = no distance trigger
    var dueDate: Date?
    var repeatEveryKm: Double      // 0 = no distance repeat
    var repeatEveryMonths: Int     // 0 = no time repeat
    var isActive: Bool
    var vehicle: Vehicle?

    init(title: String,
         type: ServiceType = .oilChange,
         dueOdometerKm: Double = 0,
         dueDate: Date? = nil,
         repeatEveryKm: Double = 0,
         repeatEveryMonths: Int = 0) {
        self.title = title
        self.typeRaw = type.rawValue
        self.dueOdometerKm = max(0, dueOdometerKm)
        self.dueDate = dueDate
        self.repeatEveryKm = max(0, repeatEveryKm)
        self.repeatEveryMonths = max(0, repeatEveryMonths)
        self.isActive = true
    }

    var type: ServiceType {
        get { ServiceType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
