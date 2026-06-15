import Foundation

/// Pure 20-20-20 scheduling logic. All inputs passed in; no side effects.
/// Every division and array access is guarded.
struct BreakScheduler {
    /// How long between recommended breaks, in seconds (always > 0 by caller contract).
    let intervalSeconds: Double
    /// The user's daily break goal (always >= 1 by caller contract).
    let dailyGoal: Int

    init(intervalSeconds: Double, dailyGoal: Int) {
        self.intervalSeconds = max(1, intervalSeconds)
        self.dailyGoal = max(1, dailyGoal)
    }

    /// Seconds since the most recent break (or since `referenceStart` if there is none yet).
    /// Returns 0 if the last break is somehow in the future (clock changes).
    func secondsSinceLastBreak(lastBreak: Date?, referenceStart: Date, now: Date = .now) -> Double {
        let anchor = lastBreak ?? referenceStart
        return max(0, now.timeIntervalSince(anchor))
    }

    /// Fraction of the interval elapsed since the last break, clamped 0...1.
    func progress(lastBreak: Date?, referenceStart: Date, now: Date = .now) -> Double {
        let elapsed = secondsSinceLastBreak(lastBreak: lastBreak, referenceStart: referenceStart, now: now)
        let p = elapsed / intervalSeconds
        return min(1, max(0, p))
    }

    /// Whether a break is due now (a full interval has elapsed).
    func isBreakDue(lastBreak: Date?, referenceStart: Date, now: Date = .now) -> Bool {
        secondsSinceLastBreak(lastBreak: lastBreak, referenceStart: referenceStart, now: now) >= intervalSeconds
    }

    /// Whole seconds remaining until the next break is due (0 once due).
    func secondsUntilDue(lastBreak: Date?, referenceStart: Date, now: Date = .now) -> Int {
        let remaining = intervalSeconds - secondsSinceLastBreak(lastBreak: lastBreak, referenceStart: referenceStart, now: now)
        return Int(max(0, remaining.rounded()))
    }

    /// A short "in 12 min" / "due now" style label.
    func dueLabel(lastBreak: Date?, referenceStart: Date, now: Date = .now) -> String {
        if isBreakDue(lastBreak: lastBreak, referenceStart: referenceStart, now: now) {
            return "Break due now"
        }
        let secs = secondsUntilDue(lastBreak: lastBreak, referenceStart: referenceStart, now: now)
        let mins = Int(ceil(Double(secs) / 60.0))
        if mins <= 1 { return "Next break in under a minute" }
        return "Next break in \(mins) min"
    }

    /// Today's completed breaks vs goal, fraction clamped 0...1.
    func goalProgress(breaksToday: Int) -> Double {
        let p = Double(max(0, breaksToday)) / Double(dailyGoal)
        return min(1, max(0, p))
    }

    func goalMet(breaksToday: Int) -> Bool {
        breaksToday >= dailyGoal
    }
}
