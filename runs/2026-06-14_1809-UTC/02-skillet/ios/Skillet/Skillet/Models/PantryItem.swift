import Foundation
import SwiftData

@Model
final class PantryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    /// Stored as raw string for SwiftData stability; access via `aisle`.
    var categoryRaw: String
    var inStock: Bool
    var note: String
    var dateAdded: Date

    init(name: String,
         aisle: Aisle,
         inStock: Bool = true,
         note: String = "",
         dateAdded: Date = .now) {
        self.id = UUID()
        self.name = name
        self.categoryRaw = aisle.rawValue
        self.inStock = inStock
        self.note = note
        self.dateAdded = dateAdded
    }

    var aisle: Aisle {
        get { Aisle(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Normalized name used for recipe matching.
    var normalizedName: String {
        IngredientNormalizer.normalize(name)
    }
}
