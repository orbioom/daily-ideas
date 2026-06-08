import Foundation
import SwiftData

/// One fasting window the user started. While `end` is nil the fast is in
/// progress; the elapsed time is always derived from `start` so it survives
/// relaunch with no background work.
@Model
final class Fast {
    var id: UUID
    var start: Date
    var end: Date?
    /// Target length in hours (taken from the chosen plan at start time).
    var goalHours: Double
    var planName: String
    /// 0 = unrated, 1...5 how the user felt afterward.
    var feeling: Int
    var note: String

    init(id: UUID = UUID(),
         start: Date = .now,
         end: Date? = nil,
         goalHours: Double = 16,
         planName: String = "16:8",
         feeling: Int = 0,
         note: String = "") {
        self.id = id
        self.start = start
        self.end = end
        self.goalHours = goalHours
        self.planName = planName
        self.feeling = feeling
        self.note = note
    }

    var isActive: Bool { end == nil }

    /// Completed elapsed seconds (for finished fasts). For active fasts use
    /// `elapsed(now:)` so the value stays live.
    var elapsedSeconds: TimeInterval {
        (end ?? Date()).timeIntervalSince(start)
    }

    func elapsed(now: Date) -> TimeInterval {
        max(0, (end ?? now).timeIntervalSince(start))
    }

    var goalSeconds: TimeInterval { goalHours * 3600 }

    /// True if the fast reached its goal length.
    var didReachGoal: Bool {
        guard let end else { return false }
        return end.timeIntervalSince(start) >= goalSeconds
    }
}
