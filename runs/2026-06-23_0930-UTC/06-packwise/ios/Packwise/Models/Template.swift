import Foundation
import SwiftData

/// A reusable list of items the user can apply to any trip.
@Model
final class Template {
    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String
    var symbol: String
    /// True for the app's seeded starter templates (shown as suggested).
    var isBuiltIn: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateItem.template)
    var items: [TemplateItem]

    init(
        id: UUID = UUID(),
        name: String,
        detail: String = "",
        symbol: String = "list.bullet.rectangle.portrait",
        isBuiltIn: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.symbol = symbol
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.items = []
    }

    var itemCount: Int { items.count }
}

/// An item stored inside a `Template`.
@Model
final class TemplateItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var categoryRaw: String
    var sortOrder: Int
    var template: Template?

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int = 1,
        category: PackCategory,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = max(1, quantity)
        self.categoryRaw = category.rawValue
        self.sortOrder = sortOrder
    }

    var category: PackCategory {
        PackCategory(rawValue: categoryRaw) ?? .misc
    }
}
