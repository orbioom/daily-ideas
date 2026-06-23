import Foundation

/// The self-grade a user gives a card during review.
/// Mapped to SM-2 quality scores.
enum ReviewGrade: Int, CaseIterable, Identifiable {
    case again = 0   // total blackout
    case hard = 3    // recalled with serious difficulty
    case good = 4    // recalled with some hesitation
    case easy = 5    // perfect recall

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    var symbol: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "tortoise.fill"
        case .good: return "checkmark"
        case .easy: return "bolt.fill"
        }
    }
}

/// Pure, deterministic SM-2 spaced-repetition scheduler.
/// Kept free of SwiftData so it is fully unit-testable and side-effect free.
enum SRSEngine {

    /// The mutated fields produced by applying a grade.
    struct Outcome {
        var easeFactor: Double
        var intervalDays: Int
        var repetitions: Int
        var lapses: Int
        var dueDate: Date
    }

    /// Apply the SM-2 algorithm to a card's current state.
    /// - Parameters:
    ///   - grade: the user's self-assessed recall quality.
    ///   - easeFactor: current ease factor.
    ///   - intervalDays: current interval in days.
    ///   - repetitions: current consecutive successes.
    ///   - lapses: current lapse count.
    ///   - now: reference date (injected for testability).
    static func schedule(
        grade: ReviewGrade,
        easeFactor: Double,
        intervalDays: Int,
        repetitions: Int,
        lapses: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Outcome {
        let q = Double(grade.rawValue)
        var ef = easeFactor
        var reps = repetitions
        var interval = intervalDays
        var lapseCount = lapses

        if grade == .again {
            // Lapse: reset reps, short relearning interval.
            reps = 0
            interval = 1
            lapseCount += 1
        } else {
            reps += 1
            switch reps {
            case 1:
                interval = 1
            case 2:
                interval = 6
            default:
                // Guard against zero/negative interval before growth.
                let base = max(1, interval)
                interval = Int((Double(base) * ef).rounded())
            }
        }

        // SM-2 ease update. Clamp to a sane floor.
        ef = ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        ef = max(1.3, ef)

        // Clamp interval to a reasonable ceiling (10 years) to avoid overflow.
        interval = min(max(interval, 1), 3650)

        let due = calendar.date(byAdding: .day, value: interval, to: startOfDay(now, calendar)) ?? now

        return Outcome(
            easeFactor: ef,
            intervalDays: interval,
            repetitions: reps,
            lapses: lapseCount,
            dueDate: due
        )
    }

    private static func startOfDay(_ date: Date, _ cal: Calendar) -> Date {
        cal.startOfDay(for: date)
    }
}
