import Foundation
import SwiftData

enum CampType: String, Codable, CaseIterable {
    case car = "Car Camping"
    case backpacking = "Backpacking"
    case rv = "RV / Van"
    case glamping = "Glamping"
    case canoe = "Canoe/Boat"
}

enum TripStatus: String, Codable, CaseIterable {
    case planned = "Planned"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

enum GearCategory: String, Codable, CaseIterable {
    case shelter = "Shelter"
    case sleep = "Sleep"
    case kitchen = "Kitchen"
    case clothing = "Clothing"
    case safety = "Safety"
    case hygiene = "Hygiene"
    case navigation = "Navigation"
    case lighting = "Lighting"
    case entertainment = "Entertainment"
    case other = "Other"

    var icon: String {
        switch self {
        case .shelter: return "tent.fill"
        case .sleep: return "bed.double.fill"
        case .kitchen: return "fork.knife"
        case .clothing: return "tshirt.fill"
        case .safety: return "cross.case.fill"
        case .hygiene: return "drop.fill"
        case .navigation: return "map.fill"
        case .lighting: return "flashlight.on.fill"
        case .entertainment: return "guitars.fill"
        case .other: return "bag.fill"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}

enum MealPrep: String, Codable, CaseIterable {
    case campfire = "Campfire"
    case stove = "Camp Stove"
    case noCook = "No Cook"
    case raw = "Raw"
    case cooler = "Cooler"
}

enum NatureCategory: String, Codable, CaseIterable {
    case wildlife = "Wildlife"
    case plant = "Plant"
    case weather = "Weather"
    case sky = "Sky"
    case landscape = "Landscape"
    case sound = "Sound"
    case water = "Water"
    case other = "Other"

    var icon: String {
        switch self {
        case .wildlife: return "hare.fill"
        case .plant: return "leaf.fill"
        case .weather: return "cloud.sun.fill"
        case .sky: return "star.fill"
        case .landscape: return "mountain.2.fill"
        case .sound: return "ear.fill"
        case .water: return "water.waves"
        case .other: return "binoculars.fill"
        }
    }
}

@Model
final class CampTrip {
    var id: UUID
    var name: String
    var campsite: String
    var location: String
    var startDate: Date
    var endDate: Date
    var status: TripStatus
    var campType: CampType
    var rating: Int
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \GearItem.trip)
    var gearItems: [GearItem]

    @Relationship(deleteRule: .cascade, inverse: \MealPlan.trip)
    var mealPlans: [MealPlan]

    @Relationship(deleteRule: .cascade, inverse: \NatureLog.trip)
    var natureLogs: [NatureLog]

    init(name: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.name = name
        self.campsite = ""
        self.location = ""
        self.startDate = startDate
        self.endDate = endDate
        self.status = .planned
        self.campType = .car
        self.rating = 0
        self.notes = ""
        self.createdAt = Date()
        self.gearItems = []
        self.mealPlans = []
        self.natureLogs = []
    }

    var duration: Int {
        max(1, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
    }

    var packedCount: Int { gearItems.filter { $0.packed }.count }
    var gearProgress: Double {
        guard !gearItems.isEmpty else { return 0 }
        return Double(packedCount) / Double(gearItems.count)
    }

    var daysUntil: Int? {
        let now = Date()
        guard startDate > now else { return nil }
        return Calendar.current.dateComponents([.day], from: now, to: startDate).day
    }
}

@Model
final class GearItem {
    var id: UUID
    var name: String
    var category: GearCategory
    var packed: Bool
    var owned: Bool
    var weight: Double
    var notes: String
    var trip: CampTrip?

    init(name: String, category: GearCategory, trip: CampTrip) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.packed = false
        self.owned = true
        self.weight = 0
        self.notes = ""
        self.trip = trip
    }
}

@Model
final class MealPlan {
    var id: UUID
    var dayNumber: Int
    var mealType: MealType
    var description: String
    var prepMethod: MealPrep
    var servings: Int
    var ingredients: String
    var trip: CampTrip?

    init(dayNumber: Int, mealType: MealType, description: String, trip: CampTrip) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.mealType = mealType
        self.description = description
        self.prepMethod = .campfire
        self.servings = 2
        self.ingredients = ""
        self.trip = trip
    }
}

@Model
final class NatureLog {
    var id: UUID
    var date: Date
    var category: NatureCategory
    var title: String
    var description: String
    var locationNote: String
    var trip: CampTrip?

    init(category: NatureCategory, title: String, trip: CampTrip) {
        self.id = UUID()
        self.date = Date()
        self.category = category
        self.title = title
        self.description = ""
        self.locationNote = ""
        self.trip = trip
    }
}

@Model
final class CampSettings {
    var onboardingComplete: Bool
    var defaultGearCategories: Bool
    var weightUnit: String
    var showCountdown: Bool
    var defaultCampType: CampType

    init() {
        self.onboardingComplete = false
        self.defaultGearCategories = true
        self.weightUnit = "oz"
        self.showCountdown = true
        self.defaultCampType = .car
    }
}
