import Foundation
import SwiftData

/// The core larder record: something you have, where it lives, how much, and when
/// it goes off. Location and Category are optional references so an item survives the
/// deletion of either. Expiry/low-stock logic lives in `ExpiryLogic`, not here, to
/// keep the model a plain data holder.
@Model
final class Item {
    var id: UUID
    var name: String
    var quantity: Double
    /// Stored as the unit's raw value for a stable schema; surfaced via `unit`.
    var unitRaw: String
    var purchaseDate: Date?
    var expiryDate: Date?
    /// At or below this quantity, the item is "low" and joins the shopping list.
    var lowStockThreshold: Double
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    var location: Location?
    var category: Category?

    init(id: UUID = UUID(),
         name: String,
         quantity: Double = 1,
         unit: Unit = .piece,
         purchaseDate: Date? = nil,
         expiryDate: Date? = nil,
         lowStockThreshold: Double = 1,
         notes: String = "",
         location: Location? = nil,
         category: Category? = nil,
         createdAt: Date = .now,
         updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.purchaseDate = purchaseDate
        self.expiryDate = expiryDate
        self.lowStockThreshold = lowStockThreshold
        self.notes = notes
        self.location = location
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Resolved unit; falls back to `.piece` if a stored raw value is ever unrecognized.
    var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .piece }
        set { unitRaw = newValue.rawValue }
    }

    /// Quantity rendered with its unit (e.g. "2 pcs").
    var quantityLabel: String {
        unit.format(quantity)
    }

    /// True when at or below the configured low-stock threshold.
    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }
}
