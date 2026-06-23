import Foundation
import SwiftData

/// A recurring feeding entry for a pet, e.g. "Breakfast — 60g kibble at 07:30".
@Model
final class FeedingSchedule {
    var id: UUID
    var label: String
    var food: String
    var portion: String
    /// Minutes-from-midnight for the scheduled time of day (0...1439).
    var timeMinutes: Int
    var notes: String
    var isActive: Bool
    var createdAt: Date

    var pet: Pet?

    init(
        id: UUID = UUID(),
        label: String,
        food: String = "",
        portion: String = "",
        timeMinutes: Int,
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.label = label
        self.food = food
        self.portion = portion
        self.timeMinutes = min(1439, max(0, timeMinutes))
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }

    /// The scheduled time mapped onto today's date.
    var todayTime: Date {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        return cal.date(byAdding: .minute, value: timeMinutes, to: start) ?? start
    }

    var timeText: String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: todayTime)
    }
}
