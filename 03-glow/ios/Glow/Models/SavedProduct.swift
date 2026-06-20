import Foundation
import SwiftData

@Model
final class SavedProduct {
    var id: UUID
    var name: String
    var brand: String
    var category: String
    var ingredientListText: String
    var overallRating: Int
    var dateAdded: Date
    var isFavorite: Bool
    var notes: String

    init(
        id: UUID = UUID(),
        name: String,
        brand: String,
        category: String,
        ingredientListText: String,
        overallRating: Int,
        dateAdded: Date = Date(),
        isFavorite: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.ingredientListText = ingredientListText
        self.overallRating = overallRating
        self.dateAdded = dateAdded
        self.isFavorite = isFavorite
        self.notes = notes
    }

    var ratingLabel: String {
        switch overallRating {
        case 1: return "Clean"
        case 2: return "Good"
        case 3: return "Moderate"
        case 4: return "Caution"
        case 5: return "Avoid"
        default: return "Unknown"
        }
    }
}
