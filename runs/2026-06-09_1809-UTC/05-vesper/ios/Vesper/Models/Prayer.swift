import Foundation
import SwiftData

/// A single prayer the user is holding — a request, a thanksgiving, a name lifted
/// up. It carries its own timeline of `PrayerUpdate`s and can be marked answered.
@Model
final class Prayer {
    var title: String
    var body: String
    var categoryRaw: String
    var statusRaw: String
    var personName: String
    var isPinned: Bool
    var createdAt: Date
    var answeredAt: Date?
    var answeredNote: String

    /// Reflections added over time. Owned by the prayer and removed with it.
    @Relationship(deleteRule: .cascade, inverse: \PrayerUpdate.prayer)
    var updates: [PrayerUpdate]

    init(title: String,
         body: String = "",
         category: PrayerCategory = .petition,
         status: PrayerStatus = .praying,
         personName: String = "",
         isPinned: Bool = false,
         createdAt: Date = .now,
         answeredAt: Date? = nil,
         answeredNote: String = "") {
        self.title = title
        self.body = body
        self.categoryRaw = category.rawValue
        self.statusRaw = status.rawValue
        self.personName = personName
        self.isPinned = isPinned
        self.createdAt = createdAt
        self.answeredAt = answeredAt
        self.answeredNote = answeredNote
        self.updates = []
    }

    var category: PrayerCategory {
        get { PrayerCategory(rawValue: categoryRaw) ?? .petition }
        set { categoryRaw = newValue.rawValue }
    }

    var status: PrayerStatus {
        get { PrayerStatus(rawValue: statusRaw) ?? .praying }
        set { statusRaw = newValue.rawValue }
    }

    var isActive: Bool { status == .praying }

    /// The most recent moment this prayer saw activity (creation or an update).
    var lastActivity: Date {
        let updateDates = updates.map(\.date)
        return ([createdAt] + updateDates).max() ?? createdAt
    }

    /// Whole days since the last activity on this prayer.
    var daysSinceActivity: Int {
        let cal = Calendar.current
        let from = cal.startOfDay(for: lastActivity)
        let to = cal.startOfDay(for: .now)
        return max(0, cal.dateComponents([.day], from: from, to: to).day ?? 0)
    }
}
