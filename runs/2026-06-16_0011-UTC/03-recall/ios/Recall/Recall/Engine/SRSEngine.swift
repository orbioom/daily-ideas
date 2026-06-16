import Foundation

/// The result of scheduling a card after a grade — pure data, no side effects.
struct SRSResult: Equatable {
    var ease: Double
    var intervalDays: Int
    var repetitions: Int
    var dueDate: Date
    var lapses: Int
}

/// A pure SM-2-derived spaced-repetition scheduler. No SwiftData, no UI — fully testable.
///
/// The algorithm is a guarded variant of SuperMemo-2 used by Anki-style apps:
/// each card carries an *ease factor* (how fast its interval grows), an *interval*
/// (days until next review), and a *repetition* count (consecutive non-lapse passes).
enum SRSEngine {
    /// Ease can never drop below this — keeps intervals from collapsing.
    static let minEase: Double = 1.3
    /// Hard cap on any interval (about 4 years) to avoid runaway scheduling.
    static let maxIntervalDays: Int = 365 * 4

    /// Start of today in the current calendar.
    static func startOfToday(_ now: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: now)
    }

    /// End of today (last instant before tomorrow's start) for due comparisons.
    static func endOfToday(_ now: Date = .now, calendar: Calendar = .current) -> Date {
        let start = calendar.startOfDay(for: now)
        let next = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return next.addingTimeInterval(-1)
    }

    /// Compute the new SRS state for a card given a grade.
    /// Reads only the card's current SRS fields, so it's trivially unit-testable.
    static func schedule(card: Card,
                         grade: Grade,
                         now: Date = .now,
                         calendar: Calendar = .current) -> SRSResult {
        schedule(ease: card.ease,
                 intervalDays: card.intervalDays,
                 repetitions: card.repetitions,
                 lapses: card.lapses,
                 grade: grade,
                 now: now,
                 calendar: calendar)
    }

    /// Core scheduling math, expressed over plain values.
    static func schedule(ease currentEase: Double,
                         intervalDays currentInterval: Int,
                         repetitions currentReps: Int,
                         lapses currentLapses: Int,
                         grade: Grade,
                         now: Date = .now,
                         calendar: Calendar = .current) -> SRSResult {
        var ease = currentEase
        var interval = currentInterval
        var reps = currentReps
        var lapses = currentLapses

        switch grade {
        case .again:
            reps = 0
            interval = 1
            ease = max(minEase, ease - 0.20)
            lapses += 1

        case .hard:
            let base = Double(max(interval, 1))
            interval = max(1, Int((base * 1.2).rounded()))
            ease = max(minEase, ease - 0.15)
            reps += 1

        case .good:
            if reps == 0 {
                interval = 1
            } else if reps == 1 {
                interval = 6
            } else {
                interval = Int((Double(interval) * ease).rounded())
            }
            // ease unchanged on Good.
            reps += 1

        case .easy:
            if reps == 0 {
                interval = 4
            } else {
                let base = Double(max(interval, 1))
                interval = Int((base * ease * 1.3).rounded())
            }
            ease += 0.15
            reps += 1
        }

        // Clamp ease and interval to safe ranges.
        ease = max(minEase, ease)
        interval = min(max(interval, 1), maxIntervalDays)

        // Due date = start-of-today + interval days (guard Calendar's optional).
        let base = calendar.startOfDay(for: now)
        let due = calendar.date(byAdding: .day, value: max(1, interval), to: base) ?? now

        return SRSResult(ease: ease,
                         intervalDays: interval,
                         repetitions: reps,
                         dueDate: due,
                         lapses: lapses)
    }

    /// Apply a scheduling result back onto a card (the only place SRS fields are mutated).
    static func apply(_ result: SRSResult, to card: Card, now: Date = .now) {
        card.ease = result.ease
        card.intervalDays = result.intervalDays
        card.repetitions = result.repetitions
        card.dueDate = result.dueDate
        card.lapses = result.lapses
        card.lastReviewed = now
    }

    // MARK: - Human-readable preview of where each grade would send a card

    /// A short label like "1d", "6d", "3w", "2mo" for a grade's resulting interval.
    static func intervalPreview(card: Card, grade: Grade, now: Date = .now) -> String {
        let r = schedule(card: card, grade: grade, now: now)
        return formatInterval(days: r.intervalDays)
    }

    static func formatInterval(days: Int) -> String {
        let d = max(1, days)
        if d < 7 { return "\(d)d" }
        if d < 30 { return "\(Int((Double(d) / 7).rounded()))w" }
        if d < 365 { return "\(Int((Double(d) / 30).rounded()))mo" }
        let years = Double(d) / 365
        return String(format: "%.1fy", years)
    }
}
