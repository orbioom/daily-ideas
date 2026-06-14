import Foundation
import SwiftData

/// Seeds a realistic, fully-funded sample budget on first launch (behind "didSeed").
/// Creates accounts, ~14 categories across groups, three months of allocations, and
/// ~70 transactions so the Budget and Reports screens are immediately rich.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }
        seed(context: context)
        didSeed = true
    }

    /// Wipe everything (cascades clean up allocations under categories).
    static func clearAll(context: ModelContext) {
        delete(Transaction.self, context: context)
        delete(Allocation.self, context: context)
        delete(Category.self, context: context)
        delete(Account.self, context: context)
        try? context.save()
    }

    private static func delete<T: PersistentModel>(_ type: T.Type, context: ModelContext) {
        let descriptor = FetchDescriptor<T>()
        if let all = try? context.fetch(descriptor) {
            for item in all { context.delete(item) }
        }
    }

    // MARK: - Build

    private static func seed(context: ModelContext) {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()

        // Month keys: this month and the two prior.
        let m0 = BudgetEngine.currentMonthKey
        let m1 = BudgetEngine.month(m0, offsetBy: -1)
        let m2 = BudgetEngine.month(m0, offsetBy: -2)
        let months = [m2, m1, m0]

        // First-of-month dates for placing transactions safely inside each month.
        func someDate(in monthKey: String, day: Int) -> Date {
            guard let first = BudgetEngine.date(forMonthKey: monthKey) else { return now }
            let range = cal.range(of: .day, in: .month, for: first)?.count ?? 28
            let safeDay = min(max(day, 1), range)
            return cal.date(byAdding: .day, value: safeDay - 1, to: first) ?? first
        }

        // MARK: Accounts
        let checking = Account(name: "Everyday Checking", type: .checking, onBudget: true, startingBalance: 0)
        let savings = Account(name: "Emergency Savings", type: .savings, onBudget: true, startingBalance: 3200)
        let cash = Account(name: "Wallet Cash", type: .cash, onBudget: true, startingBalance: 120)
        let card = Account(name: "Rewards Card", type: .creditCard, onBudget: true, startingBalance: 0)
        [checking, savings, cash, card].forEach { context.insert($0) }

        // MARK: Categories (~14 across groups)
        struct Spec { let name: String; let group: CategoryGroup; let emoji: String; let rollover: Bool; let assign: Double }
        let specs: [Spec] = [
            Spec(name: "Rent", group: .billsAndUtilities, emoji: "🏠", rollover: false, assign: 1450),
            Spec(name: "Electric", group: .billsAndUtilities, emoji: "💡", rollover: false, assign: 95),
            Spec(name: "Internet", group: .billsAndUtilities, emoji: "📶", rollover: false, assign: 60),
            Spec(name: "Phone", group: .billsAndUtilities, emoji: "📱", rollover: false, assign: 45),
            Spec(name: "Groceries", group: .food, emoji: "🛒", rollover: true, assign: 520),
            Spec(name: "Dining Out", group: .food, emoji: "🍔", rollover: true, assign: 180),
            Spec(name: "Coffee", group: .food, emoji: "☕️", rollover: true, assign: 50),
            Spec(name: "Gas", group: .transportation, emoji: "⛽️", rollover: true, assign: 140),
            Spec(name: "Transit", group: .transportation, emoji: "🚆", rollover: true, assign: 60),
            Spec(name: "Entertainment", group: .lifestyle, emoji: "🎬", rollover: true, assign: 90),
            Spec(name: "Shopping", group: .lifestyle, emoji: "🛍️", rollover: true, assign: 120),
            Spec(name: "Emergency Fund", group: .savingsGoals, emoji: "🛟", rollover: true, assign: 200),
            Spec(name: "Vacation", group: .savingsGoals, emoji: "✈️", rollover: true, assign: 150),
            Spec(name: "Card Payment", group: .debt, emoji: "💳", rollover: true, assign: 110)
        ]

        var categories: [String: Category] = [:]
        for (i, spec) in specs.enumerated() {
            let cat = Category(name: spec.name, group: spec.group, emoji: spec.emoji, rollover: spec.rollover, sortOrder: i)
            context.insert(cat)
            categories[spec.name] = cat
            // Allocate the same amount each of the three months.
            for mk in months {
                let alloc = Allocation(monthKey: mk, amount: spec.assign, category: cat)
                context.insert(alloc)
                cat.allocations.append(alloc)
            }
        }

        // MARK: Transactions
        func tx(_ payee: String, _ amount: Double, _ catName: String?, _ account: Account,
                month: String, day: Int, note: String = "") {
            let cat = catName.flatMap { categories[$0] }
            let t = Transaction(date: someDate(in: month, day: day),
                                payee: payee,
                                amount: amount,
                                note: note,
                                cleared: true,
                                categoryRef: cat,
                                accountRef: account)
            context.insert(t)
        }

        // Recurring per-month spending pattern + income, for all three months.
        for mk in months {
            // Income
            tx("Acme Payroll", 2600, nil, checking, month: mk, day: 1, note: "Salary")
            tx("Acme Payroll", 2600, nil, checking, month: mk, day: 15, note: "Salary")

            // Bills
            tx("Skyline Apartments", -1450, "Rent", checking, month: mk, day: 2)
            tx("City Power", -92, "Electric", checking, month: mk, day: 6)
            tx("Fiberline", -60, "Internet", checking, month: mk, day: 8)
            tx("CellOne", -45, "Phone", checking, month: mk, day: 10)

            // Groceries (split)
            tx("Greenmart", -118, "Groceries", checking, month: mk, day: 4)
            tx("Greenmart", -96, "Groceries", checking, month: mk, day: 12)
            tx("Corner Market", -54, "Groceries", cash, month: mk, day: 19)
            tx("Greenmart", -132, "Groceries", checking, month: mk, day: 24)

            // Dining + coffee
            tx("Noodle House", -38, "Dining Out", card, month: mk, day: 7)
            tx("Taco Stand", -22, "Dining Out", card, month: mk, day: 17)
            tx("Daily Grind", -5, "Coffee", cash, month: mk, day: 3)
            tx("Daily Grind", -5, "Coffee", cash, month: mk, day: 11)
            tx("Daily Grind", -5, "Coffee", card, month: mk, day: 21)

            // Transport
            tx("QuickFuel", -48, "Gas", card, month: mk, day: 9)
            tx("QuickFuel", -44, "Gas", card, month: mk, day: 23)
            tx("Metro Card", -30, "Transit", checking, month: mk, day: 5)

            // Lifestyle
            tx("Streamflix", -16, "Entertainment", card, month: mk, day: 14)
            tx("Bookshop", -34, "Shopping", card, month: mk, day: 20)

            // Savings transfers-as-spend (funding goals)
            tx("To Emergency Fund", -200, "Emergency Fund", savings, month: mk, day: 16)
            tx("Card Payment", -110, "Card Payment", checking, month: mk, day: 25)
        }

        // A couple of one-off extras in the current month for variety.
        tx("Birthday Gift", -65, "Shopping", card, month: m0, day: 18, note: "Friend's birthday")
        tx("Concert Tickets", -84, "Entertainment", card, month: m0, day: 22)
        tx("Refund - Streamflix", 16, "Entertainment", card, month: m1, day: 28, note: "Service credit")

        try? context.save()
    }
}
