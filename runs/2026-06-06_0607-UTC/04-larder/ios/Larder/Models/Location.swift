import Foundation
import SwiftData

/// A place items live: Pantry, Fridge, Freezer, or a custom shelf. Locations are
/// managed entities referenced by items, so the inventory groups cleanly and a
/// rename flows everywhere at once.
@Model
final class Location {
    var id: UUID
    var name: String
    /// SF Symbol glyph for the location.
    var symbol: String
    /// Manual sort order so the inventory shows Pantry/Fridge/Freezer in a stable, sensible order.
    var sortIndex: Int
    var createdAt: Date

    /// Items stored here. Nullify on delete so items aren't lost if a location is removed.
    @Relationship(deleteRule: .nullify, inverse: \Item.location)
    var items: [Item]

    init(id: UUID = UUID(),
         name: String,
         symbol: String = "archivebox",
         sortIndex: Int = 0,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.sortIndex = sortIndex
        self.createdAt = createdAt
        self.items = []
    }
}
