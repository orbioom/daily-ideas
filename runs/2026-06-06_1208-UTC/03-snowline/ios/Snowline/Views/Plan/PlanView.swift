import SwiftUI
import SwiftData

/// The payoff plan: strategy, extra payment, and the resulting debt-free date.
struct PlanView: View {
    @Query(sort: \Debt.order) private var debts: [Debt]
    @AppStorage("currencyCode") private var currency = "USD"
    @AppStorage("strategy") private var strategyRaw = Strategy.avalanche.rawValue
    @AppStorage("extraPayment") private var extra = 0.0

    private var strategy: Strategy { Strategy(rawValue: strategyRaw) ?? .avalanche }
    private var included: [Debt] { debts.filter { $0.includeInPlan && $0.balance > 0 } }
    private var inputs: [PayoffEngine.DebtInput] {
        included.map { PayoffEngine.DebtInput(id: $0.id, name: $0.name, balance: $0.balance, apr: $0.apr, minPayment: $0.minPayment) }
    }
    private var result: PayoffEngine.Result {
        PayoffEngine.simulate(debts: inputs, extra: extra, strategy: strategy, rollover: true)
    }
    private var baseMin: Double { included.reduce(0) { $0 + $1.minPayment } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if included.isEmpty {
                        EmptyStateView(icon: "flag.checkered",
                                       title: "Nothing to plan",
                                       message: "Add at least one debt (with a balance) and include it in the plan.")
                    } else { content }
                }
            }
            .navigationTitle("Plan")
            .navigationDestination(for: String.self) { _ in
                ScheduleView(result: result, currency: currency)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                strategyCard
                extraCard
                resultCard
                orderCard
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private var strategyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Strategy")
            Picker("Strategy", selection: $strategyRaw) {
                ForEach(Strategy.allCases) { Text($0.label).tag($0.rawValue) }
            }.pickerStyle(.segmented)
            Text(strategy.blurb).font(.subheadline).foregroundStyle(Brand.text2)
        }
        .glassCard()
    }

    private var extraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Eyebrow(text: "Extra payment / month")
                Spacer()
                Text(Money.string(extra, code: currency))
                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.live)
            }
            Slider(value: $extra, in: 0...max(50, baseMin * 3), step: 10)
                .accessibilityValue(Money.string(extra, code: currency))
            HStack {
                Text("Total budget: \(Money.string(baseMin + extra, code: currency))/mo")
                    .font(.caption).foregroundStyle(Brand.text3)
                Spacer()
                Button("Reset") { extra = 0 }.font(.caption)
            }
        }
        .glassCard()
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "With this plan")
            if result.stuck {
                Label("Your minimum payments don't outpace interest on at least one debt. Add extra, or raise a minimum, to make progress.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline).foregroundStyle(Brand.danger)
            } else {
                HStack(spacing: 10) {
                    StatTile(value: MonthSpan.describe(months: result.monthsToPayoff), label: "Debt-free in", tint: Brand.live)
                    StatTile(value: result.payoffDate.map { $0.formatted(.dateTime.month(.abbreviated).year()) } ?? "—", label: "Target date")
                }
                HStack(spacing: 10) {
                    StatTile(value: Money.compact(result.totalInterest, code: currency), label: "Interest paid", tint: Brand.warn)
                    StatTile(value: Money.compact(result.totalPaid, code: currency), label: "Total paid")
                }
                NavigationLink(value: "schedule") {
                    HStack {
                        Label("View month-by-month schedule", systemImage: "calendar")
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote)
                    }
                    .font(.subheadline).foregroundStyle(Brand.text)
                    .padding(.vertical, 6)
                }
            }
        }
        .glassCard()
    }

    private var orderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Payoff order")
            ForEach(Array(orderedForStrategy().enumerated()), id: \.element.id) { idx, debt in
                HStack(spacing: 12) {
                    Text("\(idx + 1)").font(Brand.mono(14, weight: .semibold)).foregroundStyle(Brand.text3)
                        .frame(width: 22)
                    Image(systemName: debt.kind.symbol).foregroundStyle(Brand.text2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(debt.name.isEmpty ? "Untitled" : debt.name).font(.subheadline.weight(.medium)).foregroundStyle(Brand.text)
                        Text("\(Money.string(debt.balance, code: currency)) · \(String(format: "%.1f%%", debt.apr))")
                            .font(.caption).foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    if let m = result.perDebtPayoffMonth[debt.id] {
                        Text(MonthSpan.describe(months: m)).font(Brand.mono(12)).foregroundStyle(Brand.live)
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .glassCard()
    }

    private func orderedForStrategy() -> [Debt] {
        switch strategy {
        case .avalanche: return included.sorted { $0.apr > $1.apr }
        case .snowball: return included.sorted { $0.balance < $1.balance }
        }
    }
}
