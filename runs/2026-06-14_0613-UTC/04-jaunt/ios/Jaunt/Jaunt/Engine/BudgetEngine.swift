import Foundation

/// Pure budget math. Guards divide-by-zero on budget percentages.
enum BudgetEngine {

    struct CategorySlice: Identifiable, Equatable {
        let id: String          // category rawValue (stable)
        let category: ItemCategory
        let amount: Double
    }

    struct Summary: Equatable {
        var planned: Double           // sum of itinerary item costs
        var logged: Double            // sum of logged expenses
        var budget: Double
        var plannedByCategory: [CategorySlice]
        var loggedByCategory: [CategorySlice]

        /// Remaining budget after logged spend. May be negative (over budget).
        var remaining: Double { budget - logged }
        var isOverBudget: Bool { budget > 0 && logged > budget }
        var hasBudget: Bool { budget > 0 }

        /// Fraction of budget spent (0...). Nil when budget is 0.
        var spentFraction: Double? {
            guard budget > 0 else { return nil }
            return logged / budget
        }
    }

    /// Sum of planned itinerary costs across all days.
    static func plannedCost(for trip: Trip) -> Double {
        trip.days.reduce(0) { acc, day in
            acc + day.items.reduce(0) { $0 + $1.cost }
        }
    }

    /// Sum of all logged expenses.
    static func loggedTotal(for trip: Trip) -> Double {
        trip.expenses.reduce(0) { $0 + $1.amount }
    }

    /// Group planned itinerary costs by category (only categories with > 0).
    static func plannedByCategory(for trip: Trip) -> [CategorySlice] {
        var totals: [ItemCategory: Double] = [:]
        for day in trip.days {
            for item in day.items where item.cost > 0 {
                totals[item.category, default: 0] += item.cost
            }
        }
        return slices(from: totals)
    }

    /// Group logged expenses by category.
    static func loggedByCategory(for trip: Trip) -> [CategorySlice] {
        var totals: [ItemCategory: Double] = [:]
        for e in trip.expenses where e.amount > 0 {
            totals[e.category, default: 0] += e.amount
        }
        return slices(from: totals)
    }

    private static func slices(from totals: [ItemCategory: Double]) -> [CategorySlice] {
        totals.map { CategorySlice(id: $0.key.rawValue, category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// Full summary for a trip.
    static func summary(for trip: Trip) -> Summary {
        Summary(
            planned: plannedCost(for: trip),
            logged: loggedTotal(for: trip),
            budget: trip.budgetAmount,
            plannedByCategory: plannedByCategory(for: trip),
            loggedByCategory: loggedByCategory(for: trip)
        )
    }

    /// Format a value with a currency symbol, no decimals when whole.
    static func currencyString(_ amount: Double, symbol: String) -> String {
        let rounded = (amount).rounded()
        if abs(amount - rounded) < 0.005 {
            return symbol + String(format: "%.0f", rounded)
        }
        return symbol + String(format: "%.2f", amount)
    }
}
