import Foundation
import SwiftData

/// Optional sample goals so charts and projections can be explored immediately.
enum SeedData {
    static func loadSample(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        let emergency = Goal(name: "Emergency fund", targetAmount: 6000,
                             targetDate: cal.date(byAdding: .month, value: 8, to: now),
                             monthlyPlan: 400, symbol: .umbrella, color: .slate, sortIndex: 0)
        context.insert(emergency)
        seedContribs(emergency, monthly: 380, months: 9, jitter: 60, context: context)

        let japan = Goal(name: "Japan trip", targetAmount: 4500,
                         targetDate: cal.date(byAdding: .month, value: 11, to: now),
                         monthlyPlan: 300, symbol: .airplane, color: .rose, sortIndex: 1)
        context.insert(japan)
        seedContribs(japan, monthly: 250, months: 6, jitter: 80, context: context)

        let laptop = Goal(name: "New laptop", targetAmount: 2200,
                          targetDate: cal.date(byAdding: .month, value: 3, to: now),
                          monthlyPlan: 0, symbol: .laptop, color: .teal, sortIndex: 2)
        context.insert(laptop)
        seedContribs(laptop, monthly: 200, months: 5, jitter: 50, context: context)

        try? context.save()
    }

    private static func seedContribs(_ goal: Goal, monthly: Double, months: Int, jitter: Double, context: ModelContext) {
        let cal = Calendar.current
        for i in 0..<months {
            guard let date = cal.date(byAdding: .month, value: -i, to: .now) else { continue }
            let wobble = jitter * sin(Double(i))
            let amount = max(20, (monthly + wobble).rounded())
            let c = Contribution(date: date, amount: amount,
                                 note: i == 0 ? "Monthly transfer" : "")
            c.goal = goal
            context.insert(c)
        }
    }
}
