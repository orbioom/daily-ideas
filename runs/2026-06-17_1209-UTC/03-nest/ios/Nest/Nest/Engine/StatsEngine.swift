import Foundation

/// A point in a cumulative-saved-over-time series.
struct SavedPoint: Identifiable {
    let id = UUID()
    let date: Date
    let cumulative: Double
}

/// A point in a per-month net-contribution series.
struct MonthlyPoint: Identifiable {
    let id = UUID()
    let monthStart: Date
    let label: String
    let net: Double
}

/// Total saved within one category.
struct CategoryTotal: Identifiable {
    let id = UUID()
    let category: GoalCategory
    let amount: Double
}

/// Aggregated stats across all active goals.
struct StatsResult {
    var goalCount: Int = 0
    var totalSaved: Double = 0
    var totalTarget: Double = 0
    var overallProgress: Double = 0          // clamped 0...1
    var onTrackCount: Int = 0
    var behindCount: Int = 0
    var savedOverTime: [SavedPoint] = []
    var monthly: [MonthlyPoint] = []
    var byCategory: [CategoryTotal] = []
    var contributionStreak: Int = 0          // consecutive months with a contribution
    var bestMonthLabel: String = "—"
    var bestMonthAmount: Double = 0

    var isEmpty: Bool { goalCount == 0 }
}

/// Pure aggregation over goals + contributions. Guards empty input & division.
enum StatsEngine {

    static func compute(goals: [Goal], asOf now: Date = .now, calendar: Calendar = .current) -> StatsResult {
        var result = StatsResult()
        let active = goals.filter { !$0.isArchived }
        result.goalCount = active.count
        guard !active.isEmpty else { return result }

        var savedTotal: Decimal = 0
        var targetTotal: Decimal = 0
        var categoryMap: [GoalCategory: Decimal] = [:]

        for goal in active {
            let summary = GoalEngine.summary(for: goal, asOf: now, calendar: calendar)
            savedTotal += summary.saved
            targetTotal += summary.target
            categoryMap[goal.category, default: 0] += summary.saved
            switch summary.status {
            case .behind: result.behindCount += 1
            case .onTrack, .ahead, .complete: result.onTrackCount += 1
            case .noDate: break
            }
        }

        result.totalSaved = (savedTotal as NSDecimalNumber).doubleValue
        result.totalTarget = (targetTotal as NSDecimalNumber).doubleValue
        result.overallProgress = result.totalTarget > 0
            ? min(max(result.totalSaved / result.totalTarget, 0), 1)
            : 0

        result.byCategory = categoryMap
            .map { CategoryTotal(category: $0.key, amount: ($0.value as NSDecimalNumber).doubleValue) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }

        // Gather all contributions chronologically.
        var all: [Contribution] = []
        for goal in active { all.append(contentsOf: goal.contributions) }
        all.sort { $0.date < $1.date }

        // Cumulative saved over time.
        var running = 0.0
        var points: [SavedPoint] = []
        for c in all {
            running += c.signedAmount
            points.append(SavedPoint(date: c.date, cumulative: running))
        }
        result.savedOverTime = points

        // Per-month net for the last 12 months.
        result.monthly = monthlySeries(contributions: all, asOf: now, calendar: calendar)

        // Streak: consecutive months (ending this month) with at least one contribution.
        result.contributionStreak = streak(contributions: all, asOf: now, calendar: calendar)

        // Best month.
        if let best = result.monthly.max(by: { $0.net < $1.net }), best.net > 0 {
            result.bestMonthLabel = best.label
            result.bestMonthAmount = best.net
        }

        return result
    }

    private static func monthlySeries(contributions: [Contribution],
                                      asOf now: Date,
                                      calendar: Calendar) -> [MonthlyPoint] {
        let df = DateFormatter()
        df.calendar = calendar
        df.dateFormat = "MMM"

        var months: [MonthlyPoint] = []
        for offset in stride(from: 11, through: 0, by: -1) {
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            guard let monthStart = calendar.date(from: comps) else { continue }
            let net = contributions
                .filter {
                    let c = calendar.dateComponents([.year, .month], from: $0.date)
                    return c.year == comps.year && c.month == comps.month
                }
                .reduce(0.0) { $0 + $1.signedAmount }
            months.append(MonthlyPoint(monthStart: monthStart, label: df.string(from: monthStart), net: net))
        }
        return months
    }

    private static func streak(contributions: [Contribution],
                               asOf now: Date,
                               calendar: Calendar) -> Int {
        guard !contributions.isEmpty else { return 0 }
        // Set of "year*12+month" buckets that had a positive deposit.
        var buckets = Set<Int>()
        for c in contributions where !c.isWithdrawal {
            let comps = calendar.dateComponents([.year, .month], from: c.date)
            if let y = comps.year, let m = comps.month { buckets.insert(y * 12 + m) }
        }
        var count = 0
        var cursor = now
        for _ in 0..<240 {
            let comps = calendar.dateComponents([.year, .month], from: cursor)
            guard let y = comps.year, let m = comps.month else { break }
            if buckets.contains(y * 12 + m) {
                count += 1
                guard let prev = calendar.date(byAdding: .month, value: -1, to: cursor) else { break }
                cursor = prev
            } else {
                break
            }
        }
        return count
    }
}
