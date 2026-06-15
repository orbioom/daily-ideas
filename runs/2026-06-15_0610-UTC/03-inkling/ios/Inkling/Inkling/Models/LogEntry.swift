import Foundation
import SwiftData

/// One day's value for one tracker. We keep at most one entry per (tracker, day) — logging
/// the same tracker again on the same day upserts the existing entry. `date` is normalised to
/// the start of its day so day-granular lookups are exact.
@Model
final class LogEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var value: Double
    var note: String?

    @Relationship var tracker: Tracker?

    init(id: UUID = UUID(),
         date: Date,
         value: Double,
         note: String? = nil,
         tracker: Tracker? = nil) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.note = note
        self.tracker = tracker
    }
}
