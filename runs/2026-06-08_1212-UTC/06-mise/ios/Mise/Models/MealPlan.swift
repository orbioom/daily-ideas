import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "carrot.fill"
        }
    }
    var sortIndex: Int { MealType.allCases.firstIndex(of: self) ?? 0 }
}

@Model
final class MealPlan {
    var id: UUID
    var date: Date              // start of day
    var mealTypeRaw: String
    var servings: Int
    var recipe: Recipe?

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .dinner }
        set { mealTypeRaw = newValue.rawValue }
    }

    init(id: UUID = UUID(), date: Date, mealType: MealType = .dinner, servings: Int = 2, recipe: Recipe? = nil) {
        self.id = id
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.servings = max(1, servings)
        self.recipe = recipe
    }
}
