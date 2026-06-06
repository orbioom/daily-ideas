import SwiftUI
import SwiftData

/// Side-by-side comparison of avalanche, snowball, and minimum-only.
struct CompareView: View {
    @Query(sort: \Debt.order) private var debts: [Debt]
    @AppStorage("currencyCode") private var currency = "USD"
    @AppStorage("extraPayment") private var extra = 0.0

    private var included: [Debt] { debts.filter { $0.includeInPlan && $0.balance > 0 } }
    private var inputs: [PayoffEngine.DebtInput] {
        included.map { PayoffEngine.DebtInput(id: $0.id, name: $0.name, balance: $0.balance, apr: $0.apr, minPayment: $0.minPayment) }
    }

    private var avalanche: PayoffEngine.Result { PayoffEngine.simulate(debts: inputs, extra: extra, strategy: .avalanche, rollover: true) }
    private var snowball: PayoffEngine.Result { PayoffEngine.simulate(debts: inputs, extra: extra, strategy: .snowball, rollover: true) }
    private var minimumOnly: PayoffEngine.Result { PayoffEngine.simulate(debts: inputs, extra: 0, strategy: .avalanche, rollover: false) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if included.isEmpty {
                        EmptyStateView(icon: "arrow.left.arrow.right",
                                       title: "Nothing to compare",
                                       message: "Add debts to compare payoff strategies.")
                    } else { content }
                }
            }
            .navigationTitle("Compare")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("All strategies use the same extra payment (\(Money.string(extra, code: currency))/mo). Minimum-only is the baseline — no rollover, no extra.")
                    .font(.subheadline).foregroundStyle(Brand.text2)

                methodCard("Avalanche", .avalanche, avalanche, baseline: minimumOnly, tint: Brand.live)
                methodCard("Snowball", .snowball, snowball, baseline: minimumOnly, tint: Brand.info)
                baselineCard
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private func methodCard(_ title: String, _ strategy: Strategy, _ r: PayoffEngine.Result,
                            baseline: PayoffEngine.Result, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                if !r.stuck && !baseline.stuck {
                    let saved = baseline.totalInterest - r.totalInterest
                    if saved > 1 {
                        Pill(text: "saves \(Money.compact(saved, code: currency))", tint: tint)
                    }
                }
            }
            if r.stuck {
                Text("Minimums can't outpace interest — add extra to make this work.")
                    .font(.subheadline).foregroundStyle(Brand.danger)
            } else {
                HStack(spacing: 10) {
                    StatTile(value: MonthSpan.describe(months: r.monthsToPayoff), label: "Payoff time", tint: tint)
                    StatTile(value: Money.compact(r.totalInterest, code: currency), label: "Interest", tint: Brand.warn)
                }
                if !baseline.stuck {
                    let monthsSaved = baseline.monthsToPayoff - r.monthsToPayoff
                    Text("Versus minimums: \(monthsSaved > 0 ? "\(MonthSpan.describe(months: monthsSaved)) sooner" : "same time"), \(Money.string(max(0, baseline.totalInterest - r.totalInterest), code: currency)) less interest.")
                        .font(.caption).foregroundStyle(Brand.text3)
                }
            }
        }
        .glassCard()
    }

    private var baselineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Minimum payments only").font(.headline).foregroundStyle(Brand.text)
            if minimumOnly.stuck {
                Text("With minimums alone, at least one balance never clears.")
                    .font(.subheadline).foregroundStyle(Brand.danger)
            } else {
                HStack(spacing: 10) {
                    StatTile(value: MonthSpan.describe(months: minimumOnly.monthsToPayoff), label: "Payoff time", tint: Brand.text3)
                    StatTile(value: Money.compact(minimumOnly.totalInterest, code: currency), label: "Interest", tint: Brand.danger)
                }
            }
        }
        .glassCard()
    }
}
