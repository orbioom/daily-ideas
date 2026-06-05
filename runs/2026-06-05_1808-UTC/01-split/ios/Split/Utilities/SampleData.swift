import Foundation
import SwiftData

/// Real, on-brand seed content so a first launch is a populated, realistic app —
/// not a void. Inserted once (gated by SettingsStore.hasSeeded) and reused by
/// "Reset to sample" in Settings. Always inserts into an empty store only.
enum SampleData {

    static func insert(into context: ModelContext) {
        insertWeekendTrip(into: context)
        insertFlatShare(into: context)
        insertDinner(into: context)
    }

    /// Remove every group (cascade removes members, expenses, settlements).
    static func clear(_ context: ModelContext) throws {
        let all = try context.fetch(FetchDescriptor<SplitGroup>())
        for group in all { context.delete(group) }
    }

    // MARK: - Builders

    private static func addExpense(to group: SplitGroup,
                                   title: String,
                                   amount: String,
                                   daysAgo: Int,
                                   payer: Member,
                                   participants: [Member],
                                   mode: SplitMode = .equal,
                                   weights: [Decimal] = [],
                                   exact: [Decimal] = [],
                                   notes: String = "",
                                   context: ModelContext) {
        let value = Decimal(string: amount) ?? 0
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now
        let expense = Expense(title: title, amount: value, date: date,
                              notes: notes, splitMode: mode, payer: payer)
        expense.group = group
        for (idx, member) in participants.enumerated() {
            let shareValue: Decimal
            switch mode {
            case .equal: shareValue = 0
            case .shares: shareValue = idx < weights.count ? weights[idx] : 1
            case .exact: shareValue = idx < exact.count ? exact[idx] : 0
            }
            let share = ExpenseShare(value: shareValue, member: member)
            share.expense = expense
            expense.shares.append(share)
        }
        group.expenses.append(expense)
        context.insert(expense)
    }

    private static func member(_ name: String, hue: Int, in group: SplitGroup,
                               context: ModelContext) -> Member {
        let m = Member(name: name, colorHue: hue,
                       createdAt: Calendar.current.date(byAdding: .second,
                                                        value: hue, to: .now) ?? .now)
        m.group = group
        group.members.append(m)
        context.insert(m)
        return m
    }

    // MARK: - Weekend Trip (6 members, 20+ expenses)

    private static func insertWeekendTrip(into context: ModelContext) {
        let group = SplitGroup(name: "Weekend Trip", glyph: "🏔️", currencyCode: "USD")
        context.insert(group)

        let mara = member("Mara", hue: 0, in: group, context: context)
        let theo = member("Theo", hue: 1, in: group, context: context)
        let priya = member("Priya", hue: 2, in: group, context: context)
        let leo = member("Leo", hue: 3, in: group, context: context)
        let saoirse = member("Saoirse", hue: 4, in: group, context: context)
        let noah = member("Noah", hue: 5, in: group, context: context)
        let all = [mara, theo, priya, leo, saoirse, noah]

        addExpense(to: group, title: "Cabin (3 nights)", amount: "960.00", daysAgo: 12,
                   payer: mara, participants: all, notes: "Whole cabin, split evenly.", context: context)
        addExpense(to: group, title: "Rental van", amount: "318.40", daysAgo: 12,
                   payer: theo, participants: all, context: context)
        addExpense(to: group, title: "Groceries run #1", amount: "142.18", daysAgo: 11,
                   payer: priya, participants: all, context: context)
        addExpense(to: group, title: "Gas — outbound", amount: "64.00", daysAgo: 12,
                   payer: theo, participants: all, context: context)
        addExpense(to: group, title: "Trail permits", amount: "72.00", daysAgo: 11,
                   payer: leo, participants: all, context: context)
        addExpense(to: group, title: "Dinner — first night", amount: "186.50", daysAgo: 11,
                   payer: saoirse, participants: all, context: context)
        addExpense(to: group, title: "Firewood & supplies", amount: "38.75", daysAgo: 10,
                   payer: noah, participants: all, context: context)
        addExpense(to: group, title: "Breakfast diner", amount: "98.20", daysAgo: 10,
                   payer: mara, participants: [mara, theo, priya, leo], context: context)
        addExpense(to: group, title: "Kayak rentals", amount: "240.00", daysAgo: 10,
                   payer: priya, participants: [priya, leo, saoirse, noah],
                   mode: .shares, weights: [1, 1, 2, 2],
                   notes: "Saoirse & Noah took the tandem twice.", context: context)
        addExpense(to: group, title: "Groceries run #2", amount: "88.64", daysAgo: 9,
                   payer: leo, participants: all, context: context)
        addExpense(to: group, title: "Wine & beer", amount: "76.00", daysAgo: 9,
                   payer: saoirse, participants: [mara, theo, saoirse, noah], context: context)
        addExpense(to: group, title: "Lunch — summit", amount: "54.30", daysAgo: 9,
                   payer: noah, participants: all, context: context)
        addExpense(to: group, title: "Hot spring entry", amount: "120.00", daysAgo: 8,
                   payer: theo, participants: all, context: context)
        addExpense(to: group, title: "Pizza night", amount: "112.45", daysAgo: 8,
                   payer: mara, participants: all, context: context)
        addExpense(to: group, title: "Souvenir maps", amount: "27.00", daysAgo: 8,
                   payer: priya, participants: [priya, leo, mara], context: context)
        addExpense(to: group, title: "Gas — return", amount: "61.20", daysAgo: 7,
                   payer: theo, participants: all, context: context)
        addExpense(to: group, title: "Farewell brunch", amount: "164.80", daysAgo: 7,
                   payer: leo, participants: all, context: context)
        addExpense(to: group, title: "Toll roads", amount: "24.00", daysAgo: 7,
                   payer: theo, participants: all, context: context)
        addExpense(to: group, title: "Coffee & pastries", amount: "41.60", daysAgo: 7,
                   payer: saoirse, participants: all, context: context)
        addExpense(to: group, title: "Cabin cleaning fee", amount: "90.00", daysAgo: 6,
                   payer: mara, participants: all, context: context)
        addExpense(to: group, title: "Late checkout snacks", amount: "33.30", daysAgo: 6,
                   payer: noah, participants: [theo, leo, noah], context: context)
        addExpense(to: group, title: "Group photo print", amount: "45.00", daysAgo: 5,
                   payer: priya, participants: all,
                   mode: .exact, exact: ["7.50", "7.50", "7.50", "7.50", "7.50", "7.50"],
                   notes: "Everyone chipped in $7.50.", context: context)

        // A couple of recorded settlements so history isn't empty.
        let s1 = Settlement(amount: Decimal(string: "60.00") ?? 0,
                            date: Calendar.current.date(byAdding: .day, value: -4, to: .now) ?? .now,
                            note: "Venmo", fromMember: noah, toMember: mara)
        s1.group = group
        group.settlements.append(s1)
        context.insert(s1)

        let s2 = Settlement(amount: Decimal(string: "45.00") ?? 0,
                            date: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
                            note: "Cash", fromMember: leo, toMember: theo)
        s2.group = group
        group.settlements.append(s2)
        context.insert(s2)
    }

    // MARK: - Flat Share

    private static func insertFlatShare(into context: ModelContext) {
        let group = SplitGroup(name: "The Flat", glyph: "🏠", currencyCode: "EUR")
        context.insert(group)

        let ana = member("Ana", hue: 0, in: group, context: context)
        let ben = member("Ben", hue: 1, in: group, context: context)
        let cleo = member("Cleo", hue: 2, in: group, context: context)
        let all = [ana, ben, cleo]

        addExpense(to: group, title: "Electricity", amount: "84.30", daysAgo: 20,
                   payer: ana, participants: all, context: context)
        addExpense(to: group, title: "Internet", amount: "39.99", daysAgo: 18,
                   payer: ben, participants: all, context: context)
        addExpense(to: group, title: "Cleaning supplies", amount: "26.40", daysAgo: 15,
                   payer: cleo, participants: all, context: context)
        addExpense(to: group, title: "Shared groceries", amount: "112.70", daysAgo: 10,
                   payer: ana, participants: all, context: context)
        addExpense(to: group, title: "Water bill", amount: "48.00", daysAgo: 6,
                   payer: ben, participants: all, context: context)

        let s = Settlement(amount: Decimal(string: "30.00") ?? 0,
                           date: Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now,
                           note: "Bank transfer", fromMember: cleo, toMember: ana)
        s.group = group
        group.settlements.append(s)
        context.insert(s)
    }

    // MARK: - Dinner

    private static func insertDinner(into context: ModelContext) {
        let group = SplitGroup(name: "Tasting Menu", glyph: "🍷", currencyCode: "GBP")
        context.insert(group)

        let dev = member("Dev", hue: 0, in: group, context: context)
        let ines = member("Inès", hue: 1, in: group, context: context)
        let kofi = member("Kofi", hue: 2, in: group, context: context)
        let mei = member("Mei", hue: 3, in: group, context: context)
        let all = [dev, ines, kofi, mei]

        addExpense(to: group, title: "Tasting menu x4", amount: "320.00", daysAgo: 3,
                   payer: dev, participants: all, context: context)
        addExpense(to: group, title: "Wine pairing", amount: "168.00", daysAgo: 3,
                   payer: ines, participants: [dev, ines, mei],
                   mode: .shares, weights: [1, 2, 1],
                   notes: "Inès had the reserve pour.", context: context)
        addExpense(to: group, title: "Taxi home", amount: "22.50", daysAgo: 3,
                   payer: kofi, participants: all, context: context)
    }
}
