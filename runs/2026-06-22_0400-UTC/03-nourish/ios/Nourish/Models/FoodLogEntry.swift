import Foundation
import SwiftData

@Model
final class FoodLogEntry {
    var id: UUID
    var date: Date
    var foodName: String
    var mealType: String
    var portionNote: String
    var notes: String
    var allergenTags: [String]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        foodName: String,
        mealType: String = "snack",
        portionNote: String = "medium",
        notes: String = "",
        allergenTags: [String] = []
    ) {
        self.id = id
        self.date = date
        self.foodName = foodName
        self.mealType = mealType
        self.portionNote = portionNote
        self.notes = notes
        self.allergenTags = allergenTags
    }
}

// MARK: - MealType

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }

    var defaultHour: Int {
        switch self {
        case .breakfast: return 8
        case .lunch: return 12
        case .dinner: return 18
        case .snack: return 15
        }
    }
}

// MARK: - PortionSize

enum PortionSize: String, CaseIterable, Identifiable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}
