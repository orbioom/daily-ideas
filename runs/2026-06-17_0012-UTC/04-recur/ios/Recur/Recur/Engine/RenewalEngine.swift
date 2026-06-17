import Foundation

/// Computes renewal dates by stepping a first-billing date forward by a cycle.
/// Month / year stepping is month-end-safe and leap-safe (Calendar clamps a
/// Jan-31 monthly sub to Feb-28/29). All arithmetic is guarded — never crashes.
struct RenewalEngine {

    /// Calendar used for all stepping. Defaults to the user's current calendar.
    var calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // MARK: - Stepping

    /// The DateComponents that represent one step of the given cycle.
    private func step(for cycle: BillingCycle, multiplier: Int) -> DateComponents {
        var c = DateComponents()
        switch cycle {
        case .weekly:               c.day = 7 * multiplier
        case .biweekly:             c.day = 14 * multiplier
        case .monthly:              c.month = 1 * multiplier
        case .quarterly:            c.month = 3 * multiplier
        case .semiannual:           c.month = 6 * multiplier
        case .annual:               c.year = 1 * multiplier
        case .customDays(let d):    c.day = max(1, d) * multiplier
        }
        return c
    }

    /// Advances `date` by `count` cycles. Returns the input if Calendar can't add.
    func advance(_ date: Date, by cycle: BillingCycle, count: Int = 1) -> Date {
        calendar.date(byAdding: step(for: cycle, multiplier: count), to: date) ?? date
    }

    // MARK: - Next / previous renewal

    /// The first renewal date that is strictly after `reference` (default now),
    /// starting from `firstBillingDate`. Month-end-safe via Calendar.
    func nextRenewal(firstBillingDate: Date,
                     cycle: BillingCycle,
                     reference: Date = Date()) -> Date {
        // If the first billing date is still in the future, that's the next renewal.
        if firstBillingDate > reference { return firstBillingDate }

        var candidate = firstBillingDate
        // Bound the loop generously so a pathological input can never spin forever.
        var guardCounter = 0
        let maxIterations = 100_000
        while candidate <= reference && guardCounter < maxIterations {
            let advanced = advance(candidate, by: cycle)
            // If Calendar failed to advance (returned the same date), bail out.
            if advanced <= candidate { return advanced }
            candidate = advanced
            guardCounter += 1
        }
        return candidate
    }

    /// The renewal immediately before `reference` (the current period's start),
    /// or `firstBillingDate` if billing hasn't started yet.
    func previousRenewal(firstBillingDate: Date,
                         cycle: BillingCycle,
                         reference: Date = Date()) -> Date {
        if firstBillingDate >= reference { return firstBillingDate }
        let next = nextRenewal(firstBillingDate: firstBillingDate, cycle: cycle, reference: reference)
        // One step back from the next renewal is the previous one.
        let prev = advance(next, by: cycle, count: -1)
        // Never return something before the first billing date.
        return max(prev, firstBillingDate)
    }

    // MARK: - Days until

    /// Whole calendar days from `reference` (start of day) to the next renewal.
    /// 0 means "renews today". Guarded against nil component results.
    func daysUntilRenewal(firstBillingDate: Date,
                          cycle: BillingCycle,
                          reference: Date = Date()) -> Int {
        let next = nextRenewal(firstBillingDate: firstBillingDate, cycle: cycle, reference: reference)
        let startRef = calendar.startOfDay(for: reference)
        let startNext = calendar.startOfDay(for: next)
        let comps = calendar.dateComponents([.day], from: startRef, to: startNext)
        return max(0, comps.day ?? 0)
    }

    /// Whole days from `reference` to an arbitrary `date` (can be negative).
    func days(from reference: Date, to date: Date) -> Int {
        let a = calendar.startOfDay(for: reference)
        let b = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: a, to: b).day ?? 0
    }
}
