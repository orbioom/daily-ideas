import Foundation

/// Pure, value-type money math for Split. No SwiftData, no UIKit — fully unit-thinkable
/// and hand-verifiable. All amounts are Decimal and round to the currency's minor unit
/// (2 decimal places). Shares always reconcile exactly to the expense total.
enum BalanceEngine {

    // MARK: - Value-type inputs (decoupled from @Model)

    /// A participant's weight/amount in one expense.
    struct ShareInput {
        let memberID: UUID
        /// Exact amount (exact mode) or weight (shares mode); ignored for equal.
        let value: Decimal
    }

    struct ExpenseInput {
        let payerID: UUID?
        let amount: Decimal
        let mode: SplitMode
        let shares: [ShareInput]
    }

    struct SettlementInput {
        let fromID: UUID?
        let toID: UUID?
        let amount: Decimal
    }

    /// A suggested transfer that reduces total debt.
    struct Transfer: Identifiable {
        let id = UUID()
        let fromID: UUID
        let toID: UUID
        let amount: Decimal
    }

    // MARK: - Rounding

    /// Round to 2 decimal places (currency minor unit), banker-free half-up.
    static func round2(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .plain)
        return result
    }

    /// One minor unit (a cent).
    static let cent = Decimal(string: "0.01") ?? Decimal()

    // MARK: - Per-expense shares

    /// Compute each participant's owed share for one expense, by mode. Returns a map
    /// memberID -> owed amount that sums EXACTLY to the (rounded) total. Returns an
    /// empty map if there are no participants.
    static func owedShares(amount rawAmount: Decimal,
                           mode: SplitMode,
                           shares: [ShareInput]) -> [UUID: Decimal] {
        let amount = round2(rawAmount)
        guard !shares.isEmpty else { return [:] }

        switch mode {
        case .equal:
            return equalShares(amount: amount, memberIDs: shares.map(\.memberID))
        case .exact:
            // Use the entered amounts directly (caller validates they sum to total).
            var result: [UUID: Decimal] = [:]
            for s in shares { result[s.memberID, default: 0] += round2(s.value) }
            return result
        case .shares:
            return weightedShares(amount: amount, shares: shares)
        }
    }

    /// Equal split with deterministic remainder distribution by cents.
    static func equalShares(amount: Decimal, memberIDs: [UUID]) -> [UUID: Decimal] {
        let n = memberIDs.count
        guard n > 0 else { return [:] }

        // Work in integer cents to avoid any drift.
        let totalCents = centsOf(amount)
        let base = totalCents / n
        let remainder = totalCents - base * n   // 0..<n extra cents

        // Sort IDs deterministically so the remainder always lands the same way.
        let ordered = memberIDs.sorted { $0.uuidString < $1.uuidString }
        var result: [UUID: Decimal] = [:]
        for (idx, id) in ordered.enumerated() {
            let extra = idx < remainder ? 1 : 0
            result[id] = decimalFromCents(base + extra)
        }
        return result
    }

    /// Weighted (shares) split. Weights need not be integers; remainder distributed
    /// by cents to the largest fractional parts, deterministically.
    static func weightedShares(amount: Decimal, shares: [ShareInput]) -> [UUID: Decimal] {
        // Collapse duplicate member rows by summing weights.
        var weightByID: [UUID: Decimal] = [:]
        for s in shares {
            let w = max(0, s.value)
            weightByID[s.memberID, default: 0] += w
        }
        let totalWeight = weightByID.values.reduce(0, +)
        let ids = weightByID.keys.sorted { $0.uuidString < $1.uuidString }

        // Degenerate: no positive weight -> fall back to equal.
        guard totalWeight > 0 else {
            return equalShares(amount: amount, memberIDs: ids)
        }

        let totalCents = centsOf(amount)
        // Ideal cents per member (Decimal), then floor and distribute remainder.
        var floored: [UUID: Int] = [:]
        var fractional: [(id: UUID, frac: Decimal)] = []
        var assigned = 0
        for id in ids {
            let weight = weightByID[id] ?? 0
            let ideal = Decimal(totalCents) * weight / totalWeight
            let floorCents = intFloor(ideal)
            floored[id] = floorCents
            assigned += floorCents
            fractional.append((id, ideal - Decimal(floorCents)))
        }
        var remainder = totalCents - assigned   // cents still to hand out

        // Give one extra cent to the largest fractional parts first; ties broken by ID.
        let order = fractional.sorted {
            if $0.frac == $1.frac { return $0.id.uuidString < $1.id.uuidString }
            return $0.frac > $1.frac
        }
        var result: [UUID: Decimal] = [:]
        for id in ids { result[id] = decimalFromCents(floored[id] ?? 0) }
        var i = 0
        while remainder > 0 && !order.isEmpty {
            let id = order[i % order.count].id
            result[id, default: 0] += cent
            remainder -= 1
            i += 1
        }
        return result
    }

    // MARK: - Net balances

    /// Net balance per member across all expenses minus recorded settlements.
    /// Positive = is owed money; negative = owes money. Sums to ~0 across the group.
    static func netBalances(memberIDs: [UUID],
                            expenses: [ExpenseInput],
                            settlements: [SettlementInput]) -> [UUID: Decimal] {
        var net: [UUID: Decimal] = [:]
        for id in memberIDs { net[id] = 0 }

        for e in expenses {
            let owed = owedShares(amount: e.amount, mode: e.mode, shares: e.shares)
            // Each participant's share is a debit.
            for (id, share) in owed {
                net[id, default: 0] -= share
            }
            // The payer is credited the full amount they fronted.
            if let payer = e.payerID {
                net[payer, default: 0] += round2(e.amount)
            }
        }

        // A settlement: the payer reduces what they owe (credit), the receiver
        // reduces what they're owed (debit).
        for s in settlements {
            let amt = round2(s.amount)
            if let from = s.fromID { net[from, default: 0] += amt }
            if let to = s.toID { net[to, default: 0] -= amt }
        }

        // Round to cents to clear any sub-cent residue.
        for id in net.keys { net[id] = round2(net[id] ?? 0) }
        return net
    }

    // MARK: - Debt simplification (greedy min cash flow)

    /// Produce a minimal list of "from pays to amount" transfers that zero out the
    /// given net balances. Greedy: repeatedly settle the largest creditor against the
    /// largest debtor. Verified to reconcile within rounding.
    static func simplify(_ balances: [UUID: Decimal]) -> [Transfer] {
        // Split into creditors (positive) and debtors (negative), in cents.
        var creditors: [(id: UUID, cents: Int)] = []
        var debtors: [(id: UUID, cents: Int)] = []
        for (id, bal) in balances {
            let c = centsOf(bal)
            if c > 0 { creditors.append((id, c)) }
            else if c < 0 { debtors.append((id, -c)) }
        }
        // Deterministic ordering: largest first, ties by ID.
        creditors.sort { $0.cents == $1.cents ? $0.id.uuidString < $1.id.uuidString : $0.cents > $1.cents }
        debtors.sort { $0.cents == $1.cents ? $0.id.uuidString < $1.id.uuidString : $0.cents > $1.cents }

        var transfers: [Transfer] = []
        var ci = 0
        var di = 0
        while ci < creditors.count && di < debtors.count {
            let pay = min(creditors[ci].cents, debtors[di].cents)
            if pay > 0 {
                transfers.append(Transfer(fromID: debtors[di].id,
                                          toID: creditors[ci].id,
                                          amount: decimalFromCents(pay)))
            }
            creditors[ci].cents -= pay
            debtors[di].cents -= pay
            if creditors[ci].cents == 0 { ci += 1 }
            if debtors[di].cents == 0 { di += 1 }
        }
        return transfers
    }

    // MARK: - Integer-cent helpers

    /// Convert a Decimal amount to an integer number of cents (rounded).
    static func centsOf(_ value: Decimal) -> Int {
        var scaled = value * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).intValue
    }

    static func decimalFromCents(_ cents: Int) -> Decimal {
        Decimal(cents) / 100
    }

    /// Floor a Decimal to an Int.
    static func intFloor(_ value: Decimal) -> Int {
        var v = value
        var floored = Decimal()
        NSDecimalRound(&floored, &v, 0, .down)
        return NSDecimalNumber(decimal: floored).intValue
    }
}
