import Foundation

/// Pure wedding-planning math: countdown, RSVP tallies, budget rollups,
/// seating capacity, and checklist progress.
enum WeddingEngine {

    // MARK: - Countdown

    static func daysUntil(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                to: calendar.startOfDay(for: date)).day ?? 0
    }

    // MARK: - RSVP

    struct GuestSummary {
        let invitedEntries: Int
        let invitedHeads: Int
        let attendingHeads: Int
        let declinedHeads: Int
        let pendingHeads: Int
        let maybeHeads: Int
    }

    static func guestSummary(_ guests: [Guest]) -> GuestSummary {
        func heads(_ r: RSVP) -> Int {
            guests.filter { $0.rsvp == r }.reduce(0) { $0 + $1.partySize }
        }
        return GuestSummary(
            invitedEntries: guests.count,
            invitedHeads: guests.reduce(0) { $0 + $1.partySize },
            attendingHeads: heads(.yes),
            declinedHeads: heads(.no),
            pendingHeads: heads(.pending),
            maybeHeads: heads(.maybe)
        )
    }

    struct MealCount: Identifiable {
        var id: String { meal.rawValue }
        let meal: MealChoice
        let count: Int
    }

    /// Meal counts for attending + maybe guests (those likely to need a plate).
    static func mealCounts(_ guests: [Guest]) -> [MealCount] {
        var totals: [MealChoice: Int] = [:]
        for g in guests where g.rsvp == .yes || g.rsvp == .maybe {
            guard g.meal != .none else { continue }
            totals[g.meal, default: 0] += g.partySize
        }
        return totals.map { MealCount(meal: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    // MARK: - Budget

    struct BudgetSummary {
        let estimated: Double
        let actual: Double      // effective (actual or estimate)
        let paid: Double
        let remainingToPay: Double
        let totalBudget: Double
        var overBudget: Bool { totalBudget > 0 && actual > totalBudget }
        var budgetRemaining: Double { totalBudget - actual }
    }

    static func budgetSummary(_ lines: [BudgetLine], totalBudget: Double) -> BudgetSummary {
        let estimated = lines.reduce(0) { $0 + $1.estimatedCost }
        let effective = lines.reduce(0) { $0 + $1.effectiveCost }
        let paid = lines.reduce(0) { $0 + min($1.paidAmount, $1.effectiveCost) }
        let remaining = lines.reduce(0) { $0 + $1.remainingToPay }
        return BudgetSummary(estimated: estimated, actual: effective, paid: paid,
                             remainingToPay: remaining, totalBudget: totalBudget)
    }

    struct CategoryTotal: Identifiable {
        var id: String { category.rawValue }
        let category: BudgetCategory
        let amount: Double
    }

    static func budgetByCategory(_ lines: [BudgetLine]) -> [CategoryTotal] {
        var totals: [BudgetCategory: Double] = [:]
        for l in lines { totals[l.category, default: 0] += l.effectiveCost }
        return totals.filter { $0.value > 0 }
            .map { CategoryTotal(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - Seating

    struct SeatingSummary {
        let tableCount: Int
        let seatsCapacity: Int
        let seatsAssigned: Int
        let unassignedHeads: Int
        let overTables: Int
    }

    static func seatingSummary(tables: [SeatingTable], guests: [Guest]) -> SeatingSummary {
        let capacity = tables.reduce(0) { $0 + $1.capacity }
        let assigned = tables.reduce(0) { $0 + $1.seatsUsed }
        let attendingUnassigned = guests
            .filter { $0.table == nil && ($0.rsvp == .yes || $0.rsvp == .maybe) }
            .reduce(0) { $0 + $1.partySize }
        let over = tables.filter { $0.isOver }.count
        return SeatingSummary(tableCount: tables.count,
                              seatsCapacity: capacity,
                              seatsAssigned: assigned,
                              unassignedHeads: attendingUnassigned,
                              overTables: over)
    }

    // MARK: - Checklist

    struct ChecklistSummary {
        let total: Int
        let done: Int
        let overdue: Int
        var fraction: Double { total > 0 ? Double(done) / Double(total) : 0 }
    }

    static func checklistSummary(_ tasks: [ChecklistTask], now: Date = .now,
                                 calendar: Calendar = .current) -> ChecklistSummary {
        let done = tasks.filter { $0.isDone }.count
        let overdue = tasks.filter { t in
            guard !t.isDone, let due = t.dueDate else { return false }
            return calendar.startOfDay(for: due) < calendar.startOfDay(for: now)
        }.count
        return ChecklistSummary(total: tasks.count, done: done, overdue: overdue)
    }
}
