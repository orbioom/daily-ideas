import Foundation
import SwiftData

/// A reusable block you can drop onto any day with one tap — the routine
/// you keep re-scheduling. Stores a default start time-of-day in minutes.
@Model
final class BlockTemplate {
    var title: String
    var defaultStartMinute: Int
    var durationMinutes: Int
    var categoryRaw: String
    var notes: String
    var createdAt: Date

    init(title: String,
         defaultStartMinute: Int = 9 * 60,
         durationMinutes: Int = 60,
         category: BlockCategory = .work,
         notes: String = "") {
        self.title = title
        self.defaultStartMinute = defaultStartMinute
        self.durationMinutes = max(5, durationMinutes)
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.createdAt = .now
    }

    var category: BlockCategory {
        get { BlockCategory(rawValue: categoryRaw) ?? .work }
        set { categoryRaw = newValue.rawValue }
    }

    /// Build a concrete block for `day`, placing it at the template's default time.
    func makeBlock(on day: Date, calendar: Calendar = .current) -> TimeBlock {
        let start = calendar.startOfDay(for: day)
            .addingTimeInterval(Double(defaultStartMinute) * 60)
        return TimeBlock(title: title,
                         start: start,
                         durationMinutes: durationMinutes,
                         category: category,
                         notes: notes)
    }
}
