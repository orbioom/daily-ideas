import Foundation

/// A subscription paired with its next renewal date / days-until — used by feeds.
struct UpcomingRenewal: Identifiable {
    let subscription: Subscription
    let date: Date
    let daysUntil: Int
    var id: UUID { subscription.id }
}

/// A trial that is ending, with days remaining.
struct TrialAlert: Identifiable {
    let subscription: Subscription
    let endDate: Date
    let daysUntil: Int
    var id: UUID { subscription.id }
}

/// One slice of a breakdown (category or cycle), with its monthly total.
struct BreakdownSlice: Identifiable {
    let key: String
    let label: String
    let colorHex: String
    let symbol: String
    let monthlyTotal: Decimal
    var id: String { key }
}

/// Pure aggregation over a set of subscriptions. No persistence, no UI.
struct SummaryEngine {

    let subscriptions: [Subscription]
    var includeTrialsInTotal: Bool
    private let renewal: RenewalEngine

    init(subscriptions: [Subscription],
         includeTrialsInTotal: Bool = false,
         calendar: Calendar = .current) {
        self.subscriptions = subscriptions
        self.includeTrialsInTotal = includeTrialsInTotal
        self.renewal = RenewalEngine(calendar: calendar)
    }

    // MARK: - Membership

    /// Subscriptions counted toward spend totals (respects the trials toggle).
    var billableSubscriptions: [Subscription] {
        subscriptions.filter { sub in
            guard sub.isActive else { return false }
            if sub.isTrial { return includeTrialsInTotal }
            return true
        }
    }

    var activeSubscriptions: [Subscription] { subscriptions.filter { $0.isActive } }
    var trialSubscriptions: [Subscription] { subscriptions.filter { $0.isActive && $0.isTrial } }
    var cancelledSubscriptions: [Subscription] { subscriptions.filter { !$0.isActive } }

    // MARK: - Counts

    var activeCount: Int { activeSubscriptions.count }
    var trialCount: Int { trialSubscriptions.count }
    var cancelledCount: Int { cancelledSubscriptions.count }

    // MARK: - Totals

    /// Active monthly-equivalent total.
    var monthlyTotal: Decimal {
        billableSubscriptions.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
    }

    /// 12× monthly total — a clean annual projection.
    var annualProjection: Decimal {
        monthlyTotal * Decimal(12)
    }

    /// The single most expensive billable subscription by monthly equivalent.
    var mostExpensive: Subscription? {
        billableSubscriptions.max { $0.monthlyEquivalent < $1.monthlyEquivalent }
    }

    /// Average monthly cost per billable subscription (guarded division).
    var averageMonthly: Decimal {
        let count = billableSubscriptions.count
        guard count > 0 else { return 0 }
        return CostEngine.divide(monthlyTotal, by: Decimal(count)) ?? 0
    }

    // MARK: - Breakdowns

    /// Monthly spend grouped by category, largest first.
    func byCategory() -> [BreakdownSlice] {
        var totals: [SubCategory: Decimal] = [:]
        for sub in billableSubscriptions {
            totals[sub.category, default: 0] += sub.monthlyEquivalent
        }
        return totals
            .map { (cat, total) in
                BreakdownSlice(key: cat.rawValue,
                               label: cat.label,
                               colorHex: cat.defaultHex,
                               symbol: cat.symbol,
                               monthlyTotal: total)
            }
            .sorted { $0.monthlyTotal > $1.monthlyTotal }
    }

    /// Monthly spend grouped by billing cycle, largest first.
    func byCycle() -> [BreakdownSlice] {
        var totals: [String: (label: String, symbol: String, total: Decimal)] = [:]
        for sub in billableSubscriptions {
            let token = sub.cycle.token
            let existing = totals[token]
            totals[token] = (sub.cycle.label, sub.cycle.symbol,
                             (existing?.total ?? 0) + sub.monthlyEquivalent)
        }
        // Stable, distinct colors per cycle token.
        let palette: [String: String] = [
            "weekly": "E2574C", "biweekly": "E67E22", "monthly": "7C5CF0",
            "quarterly": "3B9CF0", "semiannual": "2EB0A0", "annual": "9B59B6",
            "custom": "8E8E93"
        ]
        return totals
            .map { (token, v) in
                BreakdownSlice(key: token,
                               label: v.label,
                               colorHex: palette[token] ?? "8E8E93",
                               symbol: v.symbol,
                               monthlyTotal: v.total)
            }
            .sorted { $0.monthlyTotal > $1.monthlyTotal }
    }

    // MARK: - Upcoming renewals

    /// Active, non-trial subscriptions whose next renewal is within `days` days,
    /// sorted soonest first.
    func upcomingRenewals(withinDays days: Int, reference: Date = Date()) -> [UpcomingRenewal] {
        activeSubscriptions
            .filter { !$0.isTrial }
            .map { sub -> UpcomingRenewal in
                let next = renewal.nextRenewal(firstBillingDate: sub.firstBillingDate,
                                               cycle: sub.cycle, reference: reference)
                let d = renewal.daysUntilRenewal(firstBillingDate: sub.firstBillingDate,
                                                 cycle: sub.cycle, reference: reference)
                return UpcomingRenewal(subscription: sub, date: next, daysUntil: d)
            }
            .filter { $0.daysUntil <= days }
            .sorted { $0.daysUntil < $1.daysUntil }
    }

    /// All active non-trial subscriptions sorted by next renewal (for a full feed).
    func allUpcoming(reference: Date = Date()) -> [UpcomingRenewal] {
        upcomingRenewals(withinDays: Int.max, reference: reference)
    }

    // MARK: - Trial alerts

    /// Active trials whose end date is within `leadDays`, soonest first.
    func trialsEndingSoon(leadDays: Int, reference: Date = Date()) -> [TrialAlert] {
        trialSubscriptions.compactMap { sub -> TrialAlert? in
            guard let end = sub.trialEndDate else { return nil }
            let d = renewal.days(from: reference, to: end)
            guard d <= leadDays else { return nil }
            return TrialAlert(subscription: sub, endDate: end, daysUntil: d)
        }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    // MARK: - Renewals on a given day (calendar)

    /// Subscriptions whose next renewal falls on the same calendar day as `day`.
    func renewals(on day: Date, calendar: Calendar = .current, reference: Date = Date()) -> [UpcomingRenewal] {
        allUpcoming(reference: reference).filter {
            calendar.isDate($0.date, inSameDayAs: day)
        }
    }

    /// Day-of-month -> count of renewals, for a month grid. Considers each active
    /// non-trial sub's next renewal within the displayed month.
    func renewalDays(inMonthOf monthDate: Date, calendar: Calendar = .current,
                     reference: Date = Date()) -> [Date: [UpcomingRenewal]] {
        var map: [Date: [UpcomingRenewal]] = [:]
        let upcoming = allUpcoming(reference: reference)
        for item in upcoming {
            if calendar.isDate(item.date, equalTo: monthDate, toGranularity: .month) {
                let key = calendar.startOfDay(for: item.date)
                map[key, default: []].append(item)
            }
        }
        return map
    }
}
