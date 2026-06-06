import Foundation
import SwiftData

/// A managed category that items reference (e.g. "Grains", "Dairy"). Categories are
/// first-class entities, not free text, so renames propagate and lists can group.
@Model
final class Category {
    var id: UUID
    var name: String
    /// SF Symbol name shown as the category glyph.
    var symbol: String
    /// Index into Brand.categoryPalette (wraps via modulo).
    var colorHue: Int
    var createdAt: Date

    /// Items filed under this category. Nullify on delete so items survive a category removal.
    @Relationship(deleteRule: .nullify, inverse: \Item.category)
    var items: [Item]

    init(id: UUID = UUID(),
         name: String,
         symbol: String = "tag",
         colorHue: Int = 0,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHue = colorHue
        self.createdAt = createdAt
        self.items = []
    }
}
