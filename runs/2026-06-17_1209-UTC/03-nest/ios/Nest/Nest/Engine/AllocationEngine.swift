import Foundation

/// One line of a proposed lump-sum allocation.
struct AllocationLine: Identifiable {
    let id: UUID
    let goalID: UUID
    let goalName: String
    let symbolName: String
    let colorHex: String
    let remainingBefore: Decimal
    let amount: Decimal           // amount allocated to this goal (>= 0)

    var remainingAfter: Decimal { max(remainingBefore - amount, 0) }
}

/// A complete allocation proposal that sums *exactly* to the lump.
struct AllocationPlan {
    let lump: Decimal
    let strategy: AllocationStrategy
    let lines: [AllocationLine]

    var allocatedTotal: Decimal { lines.reduce(Decimal(0)) { $0 + $1.amount } }
    var hasAllocation: Bool { lines.contains { $0.amount > 0 } }
}

/// Splits a lump sum across goals per a strategy. Pure; preview-then-apply.
enum AllocationEngine {

    /// Build a preview plan. `goals` should be the user-chosen, active goals.
    static func plan(lump rawLump: Double,
                     goals: [Goal],
                     strategy: AllocationStrategy) -> AllocationPlan {
        let lump = Money.round(max(Decimal(rawLump), 0), scale: 2)
        guard lump > 0, !goals.isEmpty else {
            return AllocationPlan(lump: lump, strategy: strategy, lines: emptyLines(goals))
        }

        // Weight per goal depends on the strategy.
        let weights = self.weights(for: goals, strategy: strategy)
        let totalWeight = weights.reduce(0, +)

        var rawAmounts: [Decimal]
        if totalWeight <= 0 {
            // Fall back to an even split when weights collapse to zero.
            let even = lump / Decimal(goals.count)
            rawAmounts = Array(repeating: even, count: goals.count)
        } else {
            rawAmounts = weights.map { lump * Decimal($0 / totalWeight) }
        }

        // Round each down to cents, then distribute the remainder a cent at a time
        // so the lines sum EXACTLY to the lump.
        var rounded = rawAmounts.map { Money.round($0, scale: 2) }
        var sum = rounded.reduce(Decimal(0), +)
        var remainder = lump - sum
        let cent = Decimal(0.01)

        // Order indices by largest fractional remainder for fair distribution.
        let fractional = zip(rawAmounts.indices, zip(rawAmounts, rounded)).map { (idx, pair) -> (Int, Decimal) in
            (idx, pair.0 - pair.1)
        }.sorted { $0.1 > $1.1 }

        var cursor = 0
        // Add cents while a positive remainder exists.
        while remainder >= cent && !fractional.isEmpty {
            let target = fractional[cursor % fractional.count].0
            rounded[target] += cent
            remainder -= cent
            cursor += 1
        }
        // If we over-shot (negative remainder), claw back cents.
        cursor = 0
        while remainder <= -cent && !fractional.isEmpty {
            let target = fractional[cursor % fractional.count].0
            if rounded[target] >= cent {
                rounded[target] -= cent
                remainder += cent
            }
            cursor += 1
            if cursor > fractional.count * 4 { break }   // safety bound
        }

        sum = rounded.reduce(Decimal(0), +)
        // Final exactness nudge onto the first non-empty line.
        let drift = lump - sum
        if drift != 0, let firstIdx = rounded.indices.first(where: { rounded[$0] + drift >= 0 }) {
            rounded[firstIdx] += drift
        }

        let lines = goals.enumerated().map { idx, goal -> AllocationLine in
            let summary = GoalEngine.summary(for: goal)
            let amount = rounded[safe: idx] ?? 0
            return AllocationLine(
                id: UUID(),
                goalID: goal.id,
                goalName: goal.name,
                symbolName: goal.symbolName,
                colorHex: goal.colorHex,
                remainingBefore: summary.remaining,
                amount: max(amount, 0)
            )
        }

        return AllocationPlan(lump: lump, strategy: strategy, lines: lines)
    }

    /// Apply a plan by appending Contributions to each goal. Returns the count applied.
    @discardableResult
    static func apply(plan: AllocationPlan,
                      goals: [Goal],
                      note: String,
                      date: Date = .now) -> Int {
        var applied = 0
        let byID = Dictionary(uniqueKeysWithValues: goals.map { ($0.id, $0) })
        for line in plan.lines where line.amount > 0 {
            guard let goal = byID[line.goalID] else { continue }
            let value = (line.amount as NSDecimalNumber).doubleValue
            let contribution = Contribution(date: date, amount: value, isWithdrawal: false, note: note, goal: goal)
            goal.contributions.append(contribution)
            applied += 1
        }
        return applied
    }

    // MARK: - Weights

    private static func weights(for goals: [Goal], strategy: AllocationStrategy) -> [Double] {
        switch strategy {
        case .evenSplit:
            return Array(repeating: 1, count: goals.count)
        case .proportionalToNeed:
            return goals.map { goal in
                let remaining = (GoalEngine.summary(for: goal).remaining as NSDecimalNumber).doubleValue
                return max(remaining, 0)
            }
        case .byPriority:
            // priority 1 (high) -> weight 3, 2 -> 2, 3 -> 1.
            return goals.map { Double(max(4 - min(max($0.priority, 1), 3), 1)) }
        }
    }

    private static func emptyLines(_ goals: [Goal]) -> [AllocationLine] {
        goals.map { goal in
            let summary = GoalEngine.summary(for: goal)
            return AllocationLine(
                id: UUID(),
                goalID: goal.id,
                goalName: goal.name,
                symbolName: goal.symbolName,
                colorHex: goal.colorHex,
                remainingBefore: summary.remaining,
                amount: 0
            )
        }
    }
}
