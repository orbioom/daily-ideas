import Foundation
import SwiftData

/// A rub / seasoning recipe. `[String]` of ingredients is a SwiftData-supported value type.
@Model
final class Rub {
    @Attribute(.unique) var id: UUID
    var name: String
    var ingredients: [String]
    var steps: String?
    var notes: String
    var isBuiltInCopy: Bool      // true when copied from a built-in classic to edit
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         ingredients: [String],
         steps: String? = nil,
         notes: String = "",
         isBuiltInCopy: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
        self.notes = notes
        self.isBuiltInCopy = isBuiltInCopy
        self.createdAt = createdAt
    }
}
