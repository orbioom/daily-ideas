import Foundation
import SwiftData

/// One line on a trip's packing checklist.
@Model
final class PackItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var categoryRaw: String
    var isPacked: Bool
    /// True when added by the user rather than the generator.
    var isCustom: Bool
    var sortOrder: Int
    var trip: Trip?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        category: PackCategory,
        isPacked: Bool = false,
        isCustom: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = max(1, quantity)
        self.categoryRaw = category.rawValue
        self.isPacked = isPacked
        self.isCustom = isCustom
        self.sortOrder = sortOrder
    }

    var category: PackCategory {
        PackCategory(rawValue: categoryRaw) ?? .misc
    }

    var displayName: String {
        quantity > 1 ? "\(name) ×\(quantity)" : name
    }
}
