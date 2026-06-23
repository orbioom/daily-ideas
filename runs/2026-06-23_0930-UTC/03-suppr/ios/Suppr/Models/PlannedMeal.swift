import Foundation
import SwiftData

/// A recipe assigned to a specific day + meal slot, with a chosen serving count.
@Model
final class PlannedMeal {
    @Attribute(.unique) var id: UUID
    /// Start-of-day date the meal is planned for.
    var day: Date
    var slotRaw: String
    /// Servings the cook wants for this meal (drives grocery scaling).
    var servings: Int
    var addedAt: Date

    var recipe: Recipe?

    init(
        id: UUID = UUID(),
        day: Date,
        slot: MealSlot,
        servings: Int,
        recipe: Recipe?,
        addedAt: Date = .now
    ) {
        self.id = id
        self.day = Calendar.current.startOfDay(for: day)
        self.slotRaw = slot.rawValue
        self.servings = max(1, servings)
        self.recipe = recipe
        self.addedAt = addedAt
    }

    var slot: MealSlot {
        get { MealSlot(rawValue: slotRaw) ?? .dinner }
        set { slotRaw = newValue.rawValue }
    }

    /// Scale factor applied to the recipe's base ingredient quantities.
    var scaleFactor: Double {
        guard let base = recipe?.servings, base > 0 else { return 1 }
        return Double(servings) / Double(base)
    }
}
