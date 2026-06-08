import Foundation
import SwiftData

enum ActivityCategory: String, Codable, CaseIterable, Identifiable {
    case sightseeing, food, transport, lodging, activity, shopping, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sightseeing: return "Sightseeing"
        case .food:        return "Food & Drink"
        case .transport:   return "Transport"
        case .lodging:     return "Lodging"
        case .activity:    return "Activity"
        case .shopping:    return "Shopping"
        case .other:       return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .sightseeing: return "camera.fill"
        case .food:        return "fork.knife"
        case .transport:   return "airplane"
        case .lodging:     return "bed.double.fill"
        case .activity:    return "figure.hiking"
        case .shopping:    return "bag.fill"
        case .other:       return "mappin.and.ellipse"
        }
    }

    var colorHex: UInt32 {
        switch self {
        case .sightseeing: return 0x3E8E9E
        case .food:        return 0xB0814E
        case .transport:   return 0x6E7BA6
        case .lodging:     return 0x9E5E7E
        case .activity:    return 0x3E9E78
        case .shopping:    return 0x7CA68F
        case .other:       return 0x8B8FA3
        }
    }
}

@Model
final class Activity {
    var id: UUID
    var title: String
    var startTime: Date
    var hasTime: Bool           // false = "all day / unscheduled" within its day
    var categoryRaw: String
    var location: String
    var notes: String
    var cost: Double
    var booked: Bool
    var trip: Trip?

    var category: ActivityCategory {
        get { ActivityCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        title: String,
        startTime: Date,
        hasTime: Bool = true,
        category: ActivityCategory = .sightseeing,
        location: String = "",
        notes: String = "",
        cost: Double = 0,
        booked: Bool = false,
        trip: Trip? = nil
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.hasTime = hasTime
        self.categoryRaw = category.rawValue
        self.location = location
        self.notes = notes
        self.cost = cost
        self.booked = booked
        self.trip = trip
    }
}
