import Foundation

/// On-track status of a goal relative to its pacing.
enum GoalStatus: String {
    case onTrack
    case behind
    case ahead
    case complete
    case noDate

    var title: String {
        switch self {
        case .onTrack: return "On track"
        case .behind: return "Behind"
        case .ahead: return "Ahead"
        case .complete: return "Funded"
        case .noDate: return "No date"
        }
    }

    var symbolName: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .behind: return "exclamationmark.triangle.fill"
        case .ahead: return "hare.fill"
        case .complete: return "star.circle.fill"
        case .noDate: return "calendar.badge.exclamationmark"
        }
    }
}

/// A computed snapshot of a goal's progress and pacing. All money in `Decimal`.
struct GoalSummary {
    let saved: Decimal
    let target: Decimal
    let remaining: Decimal
    let progressFraction: Double      // clamped 0...1
    let monthsRemaining: Int          // whole months from today to targetDate (>= 0)
    let requiredMonthly: Decimal      // remaining / max(monthsRemaining, 1)
    let recentMonthlyRate: Decimal    // avg net per month over the last 3 months
    let projectedCompletion: Date?    // nil if no meaningful rate
    let status: GoalStatus
}

/// Pure pacing math for a single goal. Guards every division and empty input.
enum GoalEngine {

    /// Net saved amount: Σ deposits − Σ withdrawals (never below zero for display).
    static func savedAmount(_ goal: Goal) -> Decimal {
        let total = goal.contributions.reduce(Decimal(0)) { $0 + Decimal($1.signedAmount) }
        return total
    }

    static func summary(for goal: Goal, asOf now: Date = .now, calendar: Calendar = .current) -> GoalSummary {
        let saved = savedAmount(goal)
        let target = Decimal(goal.targetAmount)
        let remaining = max(target - saved, 0)

        // Progress fraction, guarded against zero/negative target.
        let fraction: Double
        if goal.targetAmount > 0 {
            let raw = (saved as NSDecimalNumber).doubleValue / goal.targetAmount
            fraction = min(max(raw, 0), 1)
        } else {
            fraction = saved > 0 ? 1 : 0
        }

        // Months remaining until the target date.
        let months: Int
        if let target = goal.targetDate {
            let comps = calendar.dateComponents([.month], from: now, to: target)
            months = max(comps.month ?? 0, 0)
        } else {
            months = 0
        }

        let requiredMonthly: Decimal
        if goal.targetDate != nil {
            requiredMonthly = remaining / Decimal(max(months, 1))
        } else {
            requiredMonthly = 0
        }

        let recentRate = recentMonthlyRate(for: goal, asOf: now, calendar: calendar)

        // Projected completion based on the recent rate.
        var projected: Date? = nil
        if remaining > 0, recentRate > Decimal(0.01) {
            let monthsNeeded = (remaining as NSDecimalNumber).doubleValue
                / (recentRate as NSDecimalNumber).doubleValue
            let whole = Int(monthsNeeded.rounded(.up))
            if whole >= 0, whole < 1200 {
                projected = calendar.date(byAdding: .month, value: whole, to: now)
            }
        }

        // Status.
        let status: GoalStatus
        if remaining <= 0 {
            status = .complete
        } else if goal.targetDate == nil {
            status = .noDate
        } else if recentRate >= requiredMonthly * Decimal(1.1) {
            status = .ahead
        } else if recentRate >= requiredMonthly * Decimal(0.9) {
            status = .onTrack
        } else {
            status = .behind
        }

        return GoalSummary(
            saved: saved,
            target: target,
            remaining: remaining,
            progressFraction: fraction,
            monthsRemaining: months,
            requiredMonthly: requiredMonthly,
            recentMonthlyRate: recentRate,
            projectedCompletion: projected,
            status: status
        )
    }

    /// Average net contribution per month over the last 3 calendar months (including current).
    static func recentMonthlyRate(for goal: Goal, asOf now: Date = .now, calendar: Calendar = .current) -> Decimal {
        guard let windowStart = calendar.date(byAdding: .month, value: -2, to: startOfMonth(now, calendar: calendar)) else {
            return 0
        }
        let recent = goal.contributions.filter { $0.date >= windowStart && $0.date <= now }
        guard !recent.isEmpty else { return 0 }
        let net = recent.reduce(Decimal(0)) { $0 + Decimal($1.signedAmount) }
        // Spread across 3 months; never divide by zero.
        let rate = net / Decimal(3)
        return max(rate, 0)
    }

    private static func startOfMonth(_ date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }
}
