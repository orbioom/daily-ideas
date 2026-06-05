import Foundation

/// Bridges SwiftData @Model objects to the pure BalanceEngine and packages the
/// results views consume: net balances, simplified settlements, and group stats.
/// Computed synchronously (fast) but exposed as plain value types.
struct GroupAnalysis {

    /// A member's net balance, resolved to the Member for display.
    struct MemberBalance: Identifiable {
        let member: Member
        let net: Decimal      // + is owed, - owes
        var id: UUID { member.id }
    }

    /// A simplified "from pays to" suggestion, resolved to Members.
    struct NamedTransfer: Identifiable {
        let id = UUID()
        let from: Member
        let to: Member
        let amount: Decimal
    }

    struct Stats {
        let totalSpent: Decimal
        let expenseCount: Int
        let biggestExpense: Expense?
        let perMemberPaid: [UUID: Decimal]
        let perMemberShare: [UUID: Decimal]
    }

    let group: SplitGroup
    let balances: [MemberBalance]
    let transfers: [NamedTransfer]
    let stats: Stats

    init(group: SplitGroup) {
        self.group = group
        let members = group.orderedMembers
        let memberByID = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let memberIDs = members.map(\.id)

        // Build engine inputs from the model graph.
        let expenseInputs: [BalanceEngine.ExpenseInput] = group.expenses.map { e in
            BalanceEngine.ExpenseInput(
                payerID: e.payer?.id,
                amount: e.amount,
                mode: e.splitMode,
                shares: e.shares.compactMap { share in
                    guard let mid = share.member?.id else { return nil }
                    return BalanceEngine.ShareInput(memberID: mid, value: share.value)
                }
            )
        }
        let settlementInputs: [BalanceEngine.SettlementInput] = group.settlements.map { s in
            BalanceEngine.SettlementInput(fromID: s.fromMember?.id,
                                          toID: s.toMember?.id,
                                          amount: s.amount)
        }

        // Net balances.
        let netMap = BalanceEngine.netBalances(memberIDs: memberIDs,
                                               expenses: expenseInputs,
                                               settlements: settlementInputs)
        self.balances = members.map { MemberBalance(member: $0, net: netMap[$0.id] ?? 0) }

        // Simplified transfers, resolved to members.
        let raw = BalanceEngine.simplify(netMap)
        self.transfers = raw.compactMap { t in
            guard let from = memberByID[t.fromID], let to = memberByID[t.toID] else { return nil }
            return NamedTransfer(from: from, to: to, amount: t.amount)
        }

        // Stats: total spent, per-member paid vs share, biggest expense, count.
        var total = Decimal()
        var paid: [UUID: Decimal] = [:]
        var share: [UUID: Decimal] = [:]
        var biggest: Expense?
        for e in group.expenses {
            total += BalanceEngine.round2(e.amount)
            if let payerID = e.payer?.id {
                paid[payerID, default: 0] += BalanceEngine.round2(e.amount)
            }
            let owed = BalanceEngine.owedShares(amount: e.amount,
                                                mode: e.splitMode,
                                                shares: e.shares.compactMap { s in
                                                    guard let mid = s.member?.id else { return nil }
                                                    return BalanceEngine.ShareInput(memberID: mid, value: s.value)
                                                })
            for (id, v) in owed { share[id, default: 0] += v }
            if let b = biggest {
                if e.amount > b.amount { biggest = e }
            } else {
                biggest = e
            }
        }
        self.stats = Stats(totalSpent: total,
                           expenseCount: group.expenses.count,
                           biggestExpense: biggest,
                           perMemberPaid: paid,
                           perMemberShare: share)
    }

    /// True when everyone is settled (no outstanding transfers).
    var isSettled: Bool { transfers.isEmpty }
}
