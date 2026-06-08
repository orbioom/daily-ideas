import Foundation
import SwiftData

enum SeedData {
    static func seed(_ context: ModelContext) {
        let cal = Calendar.current
        let now = Date()

        // Budgets
        let budgets: [(Category, Double)] = [
            (.groceries, 450), (.dining, 220), (.transport, 160),
            (.entertainment, 120), (.shopping, 200), (.utilities, 180)
        ]
        for (c, l) in budgets { context.insert(BudgetItem(category: c, monthlyLimit: l)) }

        // Recurring
        let r1 = RecurringRule(title: "Salary", amount: 3200, category: .salary, isIncome: true, dayOfMonth: 1)
        let r2 = RecurringRule(title: "Rent", amount: 1100, category: .housing, isIncome: false, dayOfMonth: 1)
        let r3 = RecurringRule(title: "Streaming bundle", amount: 24.99, category: .subscriptions, isIncome: false, dayOfMonth: 5)
        [r1, r2, r3].forEach { context.insert($0) }

        // Transactions across the last ~45 days
        let samples: [(Int, Category, Double, String, Bool)] = [
            (0, .groceries, 38.40, "Market", false),
            (0, .dining, 14.20, "Lunch", false),
            (1, .transport, 22.00, "Fuel", false),
            (2, .groceries, 51.10, "Weekly shop", false),
            (3, .entertainment, 18.00, "Cinema", false),
            (4, .dining, 32.50, "Dinner out", false),
            (5, .shopping, 64.99, "Sneakers", false),
            (6, .utilities, 60.00, "Electricity", false),
            (7, .groceries, 27.80, "Top up", false),
            (9, .health, 25.00, "Pharmacy", false),
            (11, .dining, 9.90, "Coffee x3", false),
            (13, .transport, 19.50, "Rideshare", false),
            (15, .freelance, 480.00, "Side project", true),
            (16, .groceries, 44.30, "Market", false),
            (18, .entertainment, 12.99, "Concert ticket", false),
            (20, .shopping, 28.00, "Books", false),
            (22, .dining, 21.40, "Brunch", false),
            (25, .groceries, 49.90, "Weekly shop", false),
            (28, .utilities, 45.00, "Water", false),
            (31, .transport, 24.00, "Fuel", false),
            (34, .dining, 16.75, "Takeout", false),
            (38, .gifts, 35.00, "Birthday gift", false),
        ]
        for (daysAgo, cat, amt, note, income) in samples {
            let date = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            context.insert(Transaction(date: date, amount: amt, category: cat, note: note, isIncome: income))
        }

        try? context.save()
    }
}
