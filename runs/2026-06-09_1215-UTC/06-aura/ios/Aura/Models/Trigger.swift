import Foundation
import SwiftData

/// A possible attack trigger the user can attach to episodes (stress, alcohol,
/// weather change…). Built-ins seed on first launch; users add their own.
@Model
final class Trigger {
    var name: String
    var categoryRaw: String
    var isBuiltIn: Bool
    var createdAt: Date

    /// Inverse of `Attack.triggers`. Lets SwiftData cleanly unlink this trigger
    /// from every attack if it is ever deleted (many-to-many, nullify).
    @Relationship(inverse: \Attack.triggers) var attacks: [Attack] = []

    init(name: String, category: TriggerCategory = .other, isBuiltIn: Bool = false) {
        self.name = name
        self.categoryRaw = category.rawValue
        self.isBuiltIn = isBuiltIn
        self.createdAt = .now
    }

    var category: TriggerCategory {
        get { TriggerCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
