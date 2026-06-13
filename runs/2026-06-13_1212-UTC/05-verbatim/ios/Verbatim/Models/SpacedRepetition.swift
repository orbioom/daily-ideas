import Foundation

/// A lightweight SM-2-style scheduler. Each mastery level (0...5) maps to a
/// review interval; a successful study bumps the level, a poor grade holds or
/// drops it. All arithmetic is guarded so it can never crash.
enum SpacedRepetition {

    /// Days until the next review for each mastery level (index 0...5).
    static let intervals: [Int] = [1, 2, 4, 8, 16, 32]

    /// How the learner graded their recall after a study round.
    enum Grade {
        case nailed   // confident, advance a level
        case gaps     // some slips, hold the level
        case struggled // significant gaps, drop a level
    }

    static func intervalDays(for masteryLevel: Int) -> Int {
        let clamped = min(max(masteryLevel, 0), intervals.count - 1)
        return intervals[clamped]
    }

    /// The next due date given the current mastery and the last review.
    static func nextDue(masteryLevel: Int, lastReviewed: Date?) -> Date {
        let base = lastReviewed ?? .now
        let days = intervalDays(for: masteryLevel)
        return Calendar.current.date(byAdding: .day, value: days, to: base) ?? base
    }

    /// Whether a passage is due to be reviewed on `date`.
    static func isDue(masteryLevel: Int, lastReviewed: Date?, on date: Date = .now) -> Bool {
        guard let last = lastReviewed else { return true } // never reviewed → always due
        let due = nextDue(masteryLevel: masteryLevel, lastReviewed: last)
        let cal = Calendar.current
        return cal.startOfDay(for: due) <= cal.startOfDay(for: date)
    }

    /// Apply a grade to a mastery level, clamped to 0...5.
    static func updatedMastery(_ current: Int, grade: Grade) -> Int {
        let level: Int
        switch grade {
        case .nailed:    level = current + 1
        case .gaps:      level = current
        case .struggled: level = current - 1
        }
        return min(max(level, 0), 5)
    }

    /// A 0...1 score to log alongside the grade.
    static func score(for grade: Grade) -> Double {
        switch grade {
        case .nailed:    return 1.0
        case .gaps:      return 0.6
        case .struggled: return 0.2
        }
    }
}
