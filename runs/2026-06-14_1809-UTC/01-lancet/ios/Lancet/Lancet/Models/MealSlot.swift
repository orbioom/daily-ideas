import Foundation

/// Column groups for the classic logbook grid. Pre/post-meal are handled by ReadingContext.
enum MealSlot: String, Codable, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case bedtime = "Bedtime"
    case other = "Other"

    var id: String { rawValue }

    var label: String { rawValue }

    var shortLabel: String {
        switch self {
        case .breakfast: return "Bkfst"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .bedtime: return "Bed"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "sunset.fill"
        case .bedtime: return "moon.fill"
        case .other: return "circle.dotted"
        }
    }

    /// Slots shown as columns in the logbook grid (Other is excluded from the grid).
    static let gridColumns: [MealSlot] = [.breakfast, .lunch, .dinner, .bedtime]
}
