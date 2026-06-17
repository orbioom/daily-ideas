import Foundation
import SwiftData

/// Bundled sample data so rings, projections, and charts are populated on first run.
/// Idempotent: only seeds when the store is empty.
enum SeedData {

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Goal>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        seed(into: context)
    }

    /// Force-insert sample goals (used by the "Load sample data" Settings action after a wipe).
    static func seed(into context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now

        func date(monthsAgo: Int, day: Int = 12) -> Date {
            let base = cal.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let comps = cal.dateComponents([.year, .month], from: base)
            var dc = DateComponents()
            dc.year = comps.year
            dc.month = comps.month
            dc.day = day
            return cal.date(from: dc) ?? base
        }

        func future(months: Int) -> Date {
            cal.date(byAdding: .month, value: months, to: now) ?? now
        }

        // 1. Emergency Fund — steady, on track.
        let emergency = Goal(name: "Emergency Fund",
                             symbolName: "cross.case.fill",
                             colorHex: "#BE4A33",
                             targetAmount: 12000,
                             targetDate: future(months: 14),
                             startDate: date(monthsAgo: 9),
                             priority: 1,
                             category: .emergency)
        addRegular(to: emergency, amount: 500, monthsBack: 9, startDay: 3, context: context)

        // 2. Japan Trip — ahead of pace, fun bursts.
        let japan = Goal(name: "Japan Trip",
                         symbolName: "airplane",
                         colorHex: "#3A77B5",
                         targetAmount: 6000,
                         targetDate: future(months: 8),
                         startDate: date(monthsAgo: 6),
                         priority: 2,
                         category: .travel)
        japan.contributions.append(contentsOf: [
            Contribution(date: date(monthsAgo: 6, day: 5), amount: 800, note: "Kickoff", goal: japan),
            Contribution(date: date(monthsAgo: 5, day: 8), amount: 650, note: "Bonus", goal: japan),
            Contribution(date: date(monthsAgo: 4, day: 14), amount: 700, goal: japan),
            Contribution(date: date(monthsAgo: 3, day: 2), amount: 900, note: "Side gig", goal: japan),
            Contribution(date: date(monthsAgo: 3, day: 20), amount: 200, isWithdrawal: true, note: "Visa fee", goal: japan),
            Contribution(date: date(monthsAgo: 2, day: 10), amount: 750, goal: japan),
            Contribution(date: date(monthsAgo: 1, day: 9), amount: 700, goal: japan),
            Contribution(date: date(monthsAgo: 0, day: 6), amount: 650, goal: japan)
        ])

        // 3. New Roof — large, behind pace.
        let roof = Goal(name: "New Roof",
                        symbolName: "house.fill",
                        colorHex: "#2F8F5B",
                        targetAmount: 18000,
                        targetDate: future(months: 10),
                        startDate: date(monthsAgo: 7),
                        priority: 1,
                        category: .home)
        roof.contributions.append(contentsOf: [
            Contribution(date: date(monthsAgo: 7, day: 4), amount: 600, goal: roof),
            Contribution(date: date(monthsAgo: 6, day: 4), amount: 400, goal: roof),
            Contribution(date: date(monthsAgo: 5, day: 4), amount: 500, goal: roof),
            Contribution(date: date(monthsAgo: 4, day: 4), amount: 300, goal: roof),
            Contribution(date: date(monthsAgo: 3, day: 4), amount: 450, goal: roof),
            Contribution(date: date(monthsAgo: 2, day: 4), amount: 350, goal: roof),
            Contribution(date: date(monthsAgo: 1, day: 4), amount: 300, goal: roof),
            Contribution(date: date(monthsAgo: 0, day: 4), amount: 250, goal: roof)
        ])

        // 4. Christmas — seasonal, no big urgency.
        let christmas = Goal(name: "Christmas",
                             symbolName: "snowflake",
                             colorHex: "#1FA8A0",
                             targetAmount: 1500,
                             targetDate: future(months: 6),
                             startDate: date(monthsAgo: 5),
                             priority: 3,
                             category: .holiday)
        addRegular(to: christmas, amount: 150, monthsBack: 5, startDay: 18, context: context)

        // 5. Car (down payment) — nearly complete.
        let car = Goal(name: "Car Down Payment",
                       symbolName: "car.fill",
                       colorHex: "#5C6452",
                       targetAmount: 5000,
                       targetDate: future(months: 2),
                       startDate: date(monthsAgo: 8),
                       priority: 2,
                       category: .vehicle)
        car.contributions.append(contentsOf: [
            Contribution(date: date(monthsAgo: 8, day: 11), amount: 700, goal: car),
            Contribution(date: date(monthsAgo: 7, day: 11), amount: 600, goal: car),
            Contribution(date: date(monthsAgo: 6, day: 11), amount: 550, goal: car),
            Contribution(date: date(monthsAgo: 5, day: 11), amount: 600, goal: car),
            Contribution(date: date(monthsAgo: 4, day: 11), amount: 650, goal: car),
            Contribution(date: date(monthsAgo: 3, day: 11), amount: 500, goal: car),
            Contribution(date: date(monthsAgo: 2, day: 11), amount: 550, goal: car),
            Contribution(date: date(monthsAgo: 1, day: 11), amount: 500, goal: car)
        ])

        for goal in [emergency, japan, roof, christmas, car] {
            context.insert(goal)
        }
        try? context.save()
    }

    /// Append one steady monthly deposit for `monthsBack` recent months.
    private static func addRegular(to goal: Goal,
                                   amount: Double,
                                   monthsBack: Int,
                                   startDay: Int,
                                   context: ModelContext) {
        let cal = Calendar.current
        let now = Date.now
        for offset in stride(from: monthsBack, through: 0, by: -1) {
            let base = cal.date(byAdding: .month, value: -offset, to: now) ?? now
            let comps = cal.dateComponents([.year, .month], from: base)
            var dc = DateComponents()
            dc.year = comps.year
            dc.month = comps.month
            dc.day = startDay
            let when = cal.date(from: dc) ?? base
            guard when <= now else { continue }
            goal.contributions.append(Contribution(date: when, amount: amount, note: "Monthly auto-save", goal: goal))
        }
    }
}
