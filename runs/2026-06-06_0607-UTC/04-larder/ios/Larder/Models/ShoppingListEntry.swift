import Foundation
import SwiftData

/// A line on the shopping list. Two kinds:
///  - `auto`: derived from an item that is at or below its low-stock threshold. It
///    carries a weak link to the source item (`itemID`) so checking it off restocks
///    that item back into the larder.
///  - `manual`: typed by hand ("olive oil"); has no source item.
///
/// Auto entries are merged with the live low-stock set each time the list is built
/// (see `ExpiryLogic.shoppingList`) and de-duplicated by normalized name, so the
/// store only ever holds *manual* entries plus the *checked* state of any entry.
/// We persist a manual entry and the checked flag; auto entries are recomputed.
@Model
final class ShoppingListEntry {
    var id: UUID
    /// Display name. For auto entries this mirrors the source item's name at creation.
    var name: String
    /// Quantity to buy, as free text (e.g. "2", "500g") — kept simple and unit-free.
    var desiredText: String
    /// True for hand-typed entries; false for entries generated from low stock.
    var isManual: Bool
    /// Weak link to the source item for restock-on-checkoff (auto entries only).
    var itemID: UUID?
    /// When checked, the entry is "bought". Auto entries restock their item on check.
    var isChecked: Bool
    var createdAt: Date

    init(id: UUID = UUID(),
         name: String,
         desiredText: String = "",
         isManual: Bool = true,
         itemID: UUID? = nil,
         isChecked: Bool = false,
         createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.desiredText = desiredText
        self.isManual = isManual
        self.itemID = itemID
        self.isChecked = isChecked
        self.createdAt = createdAt
    }

    /// Normalized key used to de-dupe auto vs. manual entries of the same thing.
    var normalizedKey: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
