import Foundation
import SwiftData

enum RecipeCourse: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, side, dessert, snack, drink, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .breakfast: return "sun.horizon.fill"
        case .lunch: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "fork.knife"
        case .side: return "leaf.fill"
        case .dessert: return "birthday.cake.fill"
        case .snack: return "carrot.fill"
        case .drink: return "cup.and.saucer.fill"
        case .other: return "frying.pan.fill"
        }
    }
}

@Model
final class Recipe {
    var id: UUID
    var name: String
    var summary: String
    var courseRaw: String
    var servings: Int
    var prepMinutes: Int
    var cookMinutes: Int
    var sourceURL: String
    var notes: String
    var favorite: Bool
    var colorHex: UInt32
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient] = []

    @Relationship(deleteRule: .cascade, inverse: \Step.recipe)
    var steps: [Step] = []

    var course: RecipeCourse {
        get { RecipeCourse(rawValue: courseRaw) ?? .other }
        set { courseRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        course: RecipeCourse = .dinner,
        servings: Int = 2,
        prepMinutes: Int = 0,
        cookMinutes: Int = 0,
        sourceURL: String = "",
        notes: String = "",
        favorite: Bool = false,
        colorHex: UInt32 = 0xB0673E,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.courseRaw = course.rawValue
        self.servings = max(1, servings)
        self.prepMinutes = max(0, prepMinutes)
        self.cookMinutes = max(0, cookMinutes)
        self.sourceURL = sourceURL
        self.notes = notes
        self.favorite = favorite
        self.colorHex = colorHex
        self.createdAt = createdAt
    }

    var totalMinutes: Int { prepMinutes + cookMinutes }
}
