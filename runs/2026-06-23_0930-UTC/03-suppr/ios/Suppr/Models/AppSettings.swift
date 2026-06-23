import Foundation
import SwiftData

/// Single persisted settings record (created once on first launch).
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    /// Default servings used when a new recipe is dropped onto the plan.
    var defaultServings: Int
    /// Hide staple ingredients (salt, oil…) from the grocery list entirely.
    var hideStaplesOnList: Bool
    /// Subtract pantry items marked "have on hand" from the active list.
    var pantryAwareList: Bool
    /// Week starts on Monday when true, Sunday when false.
    var weekStartsMonday: Bool
    var hapticsEnabled: Bool

    init(
        id: UUID = UUID(),
        defaultServings: Int = 4,
        hideStaplesOnList: Bool = false,
        pantryAwareList: Bool = true,
        weekStartsMonday: Bool = true,
        hapticsEnabled: Bool = true
    ) {
        self.id = id
        self.defaultServings = max(1, defaultServings)
        self.hideStaplesOnList = hideStaplesOnList
        self.pantryAwareList = pantryAwareList
        self.weekStartsMonday = weekStartsMonday
        self.hapticsEnabled = hapticsEnabled
    }
}
