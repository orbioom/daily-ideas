import Foundation
import SwiftData

/// Optional sample family so the boards and stats are explorable immediately.
enum SeedData {
    static func loadSample(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        let ava = Kid(name: "Ava", color: .rose, symbol: "star.fill", weeklyAllowance: 5, sortIndex: 0)
        ava.lastAllowancePaid = cal.date(byAdding: .day, value: -3, to: now)
        context.insert(ava)
        let leo = Kid(name: "Leo", color: .blue, symbol: "bolt.fill", weeklyAllowance: 4, sortIndex: 1)
        leo.lastAllowancePaid = cal.date(byAdding: .day, value: -2, to: now)
        context.insert(leo)

        let avaChores = [
            ("Make the bed", "bed.double.fill", 0.0, 10, ChoreRepeat.daily, 0),
            ("Feed the cat", "cat.fill", 0.50, 10, .daily, 0),
            ("Tidy room", "sparkles", 1.0, 20, .custom, mask([1, 7])),
            ("Take out recycling", "trash.fill", 1.0, 15, .custom, mask([3, 6]))
        ]
        addChores(avaChores, to: ava, context: context)

        let leoChores = [
            ("Make the bed", "bed.double.fill", 0.0, 10, ChoreRepeat.daily, 0),
            ("Set the table", "fork.knife", 0.50, 10, .daily, 0),
            ("Homework done", "book.fill", 0.0, 15, .custom, mask([2, 3, 4, 5, 6])),
            ("Wash up", "shower.fill", 1.0, 20, .custom, mask([1, 4, 7]))
        ]
        addChores(leoChores, to: leo, context: context)

        // Backfill a couple of weeks of approved completions and earnings.
        for kid in [ava, leo] {
            for dayOffset in 1...14 {
                guard let day = cal.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                for chore in kid.chores where ChoreEngine.isDue(chore, on: day, calendar: cal) {
                    if Int.random(in: 0...10) < 8 {
                        let c = Completion(date: day, choreTitle: chore.title,
                                           reward: chore.reward, points: chore.points, approved: true)
                        c.kid = kid; c.chore = chore
                        context.insert(c)
                    }
                }
            }
            // A cash-out to make the ledger interesting.
            let payout = LedgerEntry(date: cal.date(byAdding: .day, value: -5, to: now) ?? now,
                                     amount: -3, kind: .payout, note: "Pocket money")
            payout.kid = kid
            context.insert(payout)
        }
        try? context.save()
    }

    private static func mask(_ weekdays: [Int]) -> Int {
        weekdays.reduce(0) { $0 | (1 << ($1 - 1)) }
    }

    private static func addChores(_ defs: [(String, String, Double, Int, ChoreRepeat, Int)],
                                  to kid: Kid, context: ModelContext) {
        for (i, d) in defs.enumerated() {
            let chore = Chore(title: d.0, symbol: d.1, reward: d.2, points: d.3,
                              repeatType: d.4, weekdaysMask: d.5, sortIndex: i)
            chore.kid = kid
            context.insert(chore)
        }
    }
}
