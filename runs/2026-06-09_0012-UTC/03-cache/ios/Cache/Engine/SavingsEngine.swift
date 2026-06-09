import Foundation

/// Pure savings math: projections, required pace, on-track checks, trends.
enum SavingsEngine {

    // MARK: - Pace from history

    /// Average monthly deposit rate from the trailing `months` window. Only
    /// positive net months count toward "are we actually saving" pace.
    static func averageMonthlyRate(for goal: Goal, months: Int = 3,
                                   now: Date = .now, calendar: Calendar = .current) -> Double {
        guard let start = calendar.date(byAdding: .month, value: -months, to: now) else { return 0 }
        let recent = goal.contributions.filter { $0.date >= start }
        let net = recent.reduce(0.0) { $0 + $1.amount }
        guard net > 0 else { return 0 }
        // Elapsed months as a fraction (min 1 so a single deposit isn't annualised wildly).
        let days = max(1, calendar.dateComponents([.day], from: start, to: now).day ?? 1)
        let elapsedMonths = max(1.0, Double(days) / 30.0)
        return net / elapsedMonths
    }

    /// Effective monthly pace: the plan if set, otherwise observed history.
    static func effectiveMonthlyPace(for goal: Goal, now: Date = .now) -> Double {
        if goal.monthlyPlan > 0 { return goal.monthlyPlan }
        return averageMonthlyRate(for: goal, now: now)
    }

    // MARK: - Projection

    /// Projected completion date from the effective monthly pace.
    static func projectedDate(for goal: Goal, now: Date = .now, calendar: Calendar = .current) -> Date? {
        guard !goal.isComplete else { return now }
        let pace = effectiveMonthlyPace(for: goal, now: now)
        guard pace > 0 else { return nil }
        let monthsNeeded = goal.remaining / pace
        let days = Int((monthsNeeded * 30.4375).rounded())
        return calendar.date(byAdding: .day, value: max(0, days), to: now)
    }

    /// Contribution per month required to reach the target by its target date.
    static func requiredMonthly(for goal: Goal, now: Date = .now, calendar: Calendar = .current) -> Double? {
        guard let target = goal.targetDate, target > now, !goal.isComplete else { return nil }
        let days = calendar.dateComponents([.day], from: now, to: target).day ?? 0
        let months = max(0.5, Double(days) / 30.4375)
        return goal.remaining / months
    }

    enum Track { case complete, noTarget, noPace, onTrack, behind }

    static func track(for goal: Goal, now: Date = .now) -> Track {
        if goal.isComplete { return .complete }
        guard goal.targetDate != nil else {
            return effectiveMonthlyPace(for: goal, now: now) > 0 ? .noTarget : .noPace
        }
        guard let projected = projectedDate(for: goal, now: now) else { return .noPace }
        guard let target = goal.targetDate else { return .noTarget }
        return projected <= target ? .onTrack : .behind
    }

    // MARK: - Aggregates

    static func totalSaved(_ goals: [Goal]) -> Double { goals.reduce(0) { $0 + $1.saved } }
    static func totalTarget(_ goals: [Goal]) -> Double { goals.reduce(0) { $0 + $1.targetAmount } }

    // MARK: - Trends

    struct MonthPoint: Identifiable {
        let id = UUID()
        let month: Date
        let deposited: Double
    }

    /// Net contributions per month across all goals, oldest → newest.
    static func monthlyContributions(_ goals: [Goal], months: Int = 6,
                                     now: Date = .now, calendar: Calendar = .current) -> [MonthPoint] {
        let all = goals.flatMap { $0.contributions }
        let startOfThis = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0..<months).reversed().compactMap { offset in
            guard let m = calendar.date(byAdding: .month, value: -offset, to: startOfThis) else { return nil }
            let total = all.filter { calendar.isDate($0.date, equalTo: m, toGranularity: .month) }
                .reduce(0.0) { $0 + $1.amount }
            return MonthPoint(month: m, deposited: total)
        }
    }

    struct CumulativePoint: Identifiable {
        let id = UUID()
        let date: Date
        let total: Double
    }

    /// Running total of all savings over time (one point per contribution date).
    static func cumulativeSavings(_ goals: [Goal]) -> [CumulativePoint] {
        let sorted = goals.flatMap { $0.contributions }.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }
        var running = 0.0
        return sorted.map { c in
            running += c.amount
            return CumulativePoint(date: c.date, total: running)
        }
    }

    /// Highest crossed milestone (0, 25, 50, 75, 100) for celebratory copy.
    static func milestone(for goal: Goal) -> Int {
        let pct = goal.progress * 100
        if pct >= 100 { return 100 }
        if pct >= 75 { return 75 }
        if pct >= 50 { return 50 }
        if pct >= 25 { return 25 }
        return 0
    }
}
