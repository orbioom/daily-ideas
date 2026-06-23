import Foundation
import SwiftData

/// A single step in tonight's wind-down routine (e.g. "Dim the lights").
/// `completedOn` records the night the user last checked it off, so the
/// checklist auto-resets each evening.
@Model
final class WindDownItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    /// SF Symbol name shown next to the step.
    var symbol: String
    /// Ordering within the routine.
    var order: Int
    /// Whether the item is part of the active routine.
    var isEnabled: Bool
    /// Calendar day (night) this step was last completed on, if any.
    var completedOn: Date?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String = "",
        symbol: String = "checkmark.circle",
        order: Int = 0,
        isEnabled: Bool = true,
        completedOn: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.order = order
        self.isEnabled = isEnabled
        self.completedOn = completedOn
    }

    /// True if this step is checked for the given night (calendar day).
    func isDone(on night: Date, calendar: Calendar = .current) -> Bool {
        guard let c = completedOn else { return false }
        return calendar.isDate(c, inSameDayAs: night)
    }
}
