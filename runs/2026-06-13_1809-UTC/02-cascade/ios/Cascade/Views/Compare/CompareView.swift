import SwiftUI
import SwiftData

struct CompareView: View {
    @Query(sort: \Debt.sortIndex) private var debts: [Debt]
    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("strategyRaw") private var strategyRaw = PayoffStrategy.snowball.rawValue
    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var totalMin: Double { debts.reduce(0) { $0 + $1.minimumPayment } }
    private var budget: Double { max(monthlyBudget, totalMin) }

    private var snowball: PayoffPlan {
        PayoffEngine.simulate(debts.map(\.snapshot), monthlyBudget: budget, strategy: .snowball)
    }
    private var avalanche: PayoffPlan {
        PayoffEngine.simulate(debts.map(\.snapshot), monthlyBudget: budget, strategy: .avalanche)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if debts.count < 2 {
                    EmptyStateView(icon: "arrow.left.arrow.right",
                                   title: "Add two or more debts",
                                   message: "Comparing strategies only matters with multiple debts. Add another to see snowball vs avalanche.")
                } else if !snowball.feasible {
                    EmptyStateView(icon: "exclamationmark.triangle.fill",
                                   title: "Raise your payment",
                                   message: "Your monthly payment doesn’t cover the minimums yet. Adjust it on the Plan tab to compare strategies.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            verdictCard
                            strategyColumn(.snowball, snowball)
                            strategyColumn(.avalanche, avalanche)
                            Text("Both plans use your \(Money.format(budget, code: currencyCode, fraction: false)) monthly payment. Snowball clears small debts first for momentum; avalanche targets the priciest interest.")
                                .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.center).padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Compare")
        }
    }

    private var verdictCard: some View {
        let sMonths = snowball.payoffMonths ?? 0
        let aMonths = avalanche.payoffMonths ?? 0
        let interestSaved = snowball.totalInterest - avalanche.totalInterest
        let timeDiff = sMonths - aMonths
        return Card(padding: 20) {
            VStack(spacing: 12) {
                Image(systemName: interestSaved > 1 ? "mountain.2.fill" : "snowflake")
                    .font(.system(size: 30)).foregroundStyle(Theme.accent)
                Text(headline(interestSaved: interestSaved, timeDiff: timeDiff))
                    .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                if interestSaved > 1 {
                    Text("Avalanche saves \(Money.format(interestSaved, code: currencyCode)) in interest"
                         + (timeDiff > 0 ? " and \(timeDiff) month\(timeDiff == 1 ? "" : "s")." : "."))
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                } else {
                    Text("They finish about the same — pick snowball for the motivation of quick wins.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func headline(interestSaved: Double, timeDiff: Int) -> String {
        if interestSaved > 1 { return "Avalanche wins on cost" }
        return "It’s a close call"
    }

    private func strategyColumn(_ s: PayoffStrategy, _ plan: PayoffPlan) -> some View {
        let isActive = strategyRaw == s.rawValue
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: s.icon).foregroundStyle(Theme.accent)
                    Text(s.label).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    if isActive { Pill(text: "Active") }
                }
                KVRow(key: "Debt-free", value: plan.payoffDate.map { Fmt.monthYear($0) } ?? "—")
                KVRow(key: "Time to payoff", value: plan.payoffMonths.map { Fmt.monthsLabel($0) } ?? "—")
                KVRow(key: "Total interest", value: Money.format(plan.totalInterest, code: currencyCode), valueColor: Theme.bad)
                Button {
                    strategyRaw = s.rawValue; Haptics.success()
                } label: {
                    Text(isActive ? "Using this plan" : "Use this plan")
                        .font(Theme.rounded(15, .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                        .background(isActive ? Theme.surfaceAlt : Theme.accent,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(isActive ? Theme.inkSoft : .white)
                }
                .disabled(isActive)
            }
        }
    }
}
