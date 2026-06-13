import Foundation
import SwiftData

enum SeedData {
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        // A realistic paycheck-to-paycheck setup.
        func biweeklyAnchor() -> Date {
            // most recent Friday as the anchor payday
            let weekday = cal.component(.weekday, from: today)   // 1=Sun..7=Sat
            let back = (weekday - 6 + 7) % 7                     // days since last Friday
            return cal.date(byAdding: .day, value: -back, to: today) ?? today
        }

        let items: [RecurringItem] = [
            RecurringItem(name: "Paycheck", amount: 1850, kind: .income, cadence: .biweekly,
                          anchorDate: biweeklyAnchor(), category: "Paycheck"),
            RecurringItem(name: "Rent", amount: 1450, kind: .bill, cadence: .monthly,
                          dayOfMonth: 1, category: "Housing"),
            RecurringItem(name: "Car payment", amount: 320, kind: .bill, cadence: .monthly,
                          dayOfMonth: 12, category: "Loan"),
            RecurringItem(name: "Electricity", amount: 95, kind: .bill, cadence: .monthly,
                          dayOfMonth: 18, category: "Utilities"),
            RecurringItem(name: "Phone & internet", amount: 110, kind: .bill, cadence: .monthly,
                          dayOfMonth: 22, category: "Phone & Internet"),
            RecurringItem(name: "Streaming bundle", amount: 38, kind: .bill, cadence: .monthly,
                          dayOfMonth: 8, category: "Subscriptions"),
            RecurringItem(name: "Car insurance", amount: 128, kind: .bill, cadence: .monthly,
                          dayOfMonth: 15, category: "Insurance"),
            RecurringItem(name: "Groceries", amount: 130, kind: .bill, cadence: .weekly,
                          anchorDate: cal.date(byAdding: .day, value: -2, to: today) ?? today,
                          category: "Groceries")
        ]
        items.forEach { context.insert($0) }

        let oneOffs: [OneOffItem] = [
            OneOffItem(name: "Dentist", amount: 180, kind: .bill,
                       date: cal.date(byAdding: .day, value: 9, to: today) ?? today, category: "Other"),
            OneOffItem(name: "Tax refund", amount: 420, kind: .income,
                       date: cal.date(byAdding: .day, value: 20, to: today) ?? today, category: "Benefits")
        ]
        oneOffs.forEach { context.insert($0) }

        try? context.save()
    }
}
