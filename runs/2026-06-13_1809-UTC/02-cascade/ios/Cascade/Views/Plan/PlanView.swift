import SwiftUI
import SwiftData
import Charts

struct PlanView: View {
    @Query(sort: \Debt.sortIndex) private var debts: [Debt]
    @AppStorage("monthlyBudget") private var monthlyBudget = 0.0
    @AppStorage("strategyRaw") private var strategyRaw = PayoffStrategy.snowball.rawValue
    @AppStorage("currencyCode") private var currencyCode = "USD"

    private var strategy: PayoffStrategy {
        get { PayoffStrategy(rawValue: strategyRaw) ?? .snowball }
    }
    private var totalMin: Double { debts.reduce(0) { $0 + $1.minimumPayment } }
    private var budget: Double { max(monthlyBudget, totalMin) }
    private var extra: Double { max(0, budget - totalMin) }

    private var plan: PayoffPlan {
        PayoffEngine.simulate(debts.map(\.snapshot), monthlyBudget: budget, strategy: strategy)
    }
    private var minOnlyPlan: PayoffPlan {
        PayoffEngine.simulate(debts.map(\.snapshot), monthlyBudget: totalMin, strategy: strategy)
    }

    private var extraRange: ClosedValue { ClosedValue(lo: 0, hi: max(50, totalMin * 3)) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if debts.isEmpty {
                    EmptyStateView(icon: "calendar.badge.clock",
                                   title: "Nothing to plan yet",
                                   message: "Add a debt or two on the Debts tab to see your payoff plan and free-date.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            strategyCard
                            budgetCard
                            resultCard
                            if plan.feasible { chartCard; orderCard }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Your plan")
        }
    }

    private var strategyCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Strategy").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                Picker("Strategy", selection: Binding(get: { strategy }, set: { strategyRaw = $0.rawValue; Haptics.tap() })) {
                    ForEach(PayoffStrategy.allCases) { s in Text(s.label).tag(s) }
                }
                .pickerStyle(.segmented)
                Text(strategy.blurb)
                    .font(Theme.rounded(13, .regular)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private var budgetCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Monthly payment").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text(Money.format(budget, code: currencyCode, fraction: false))
                        .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.accent)
                }
                Slider(value: Binding(get: { extra },
                                      set: { monthlyBudget = totalMin + max(0, $0) }),
                       in: 0...extraRange.hi, step: 5)
                    .tint(Theme.accent)
                HStack {
                    Text("Minimums \(Money.format(totalMin, code: currencyCode, fraction: false))")
                        .font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("+ \(Money.format(extra, code: currencyCode, fraction: false)) extra")
                        .font(Theme.rounded(12, .bold)).foregroundStyle(Theme.good)
                }
            }
        }
    }

    private var resultCard: some View {
        Card(padding: 20) {
            if !plan.feasible {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30)).foregroundStyle(Theme.warn)
                    Text("Budget can’t cover the minimums")
                        .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text("You owe at least \(Money.format(totalMin, code: currencyCode)) in minimums each month. Raise the payment above to build a plan.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else if let months = plan.payoffMonths, let date = plan.payoffDate {
                VStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("Debt-free by").font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft)
                        Text(Fmt.monthYear(date)).font(Theme.rounded(30, .bold)).foregroundStyle(Theme.accent)
                        Text(Fmt.monthsLabel(months) + " from now").font(Theme.rounded(13, .medium)).foregroundStyle(Theme.inkSoft)
                    }
                    HStack(spacing: 10) {
                        StatTile(value: Money.compact(plan.totalInterest, code: currencyCode), label: "Interest you’ll pay", accent: Theme.bad)
                        let saved = max(0, (minOnlyPlan.payoffMonths ?? months) - months)
                        StatTile(value: "\(saved) mo", label: "Sooner than minimums", accent: Theme.good)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "infinity").font(.system(size: 30)).foregroundStyle(Theme.warn)
                    Text("Doesn’t pay off within 50 years")
                        .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                    Text("Interest is outrunning your payment. Increase the monthly amount to find a free-date.")
                        .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var chartCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Balance over time").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                Chart(sampled(plan.months)) { pt in
                    AreaMark(x: .value("Date", pt.date), y: .value("Balance", pt.totalBalance))
                        .foregroundStyle(LinearGradient(colors: [Theme.accent.opacity(0.4), Theme.accent.opacity(0.05)],
                                                        startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("Date", pt.date), y: .value("Balance", pt.totalBalance))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                }
                .chartYAxis { AxisMarks(format: .currency(code: currencyCode).precision(.fractionLength(0))) }
                .frame(height: 180)
                .accessibilityLabel("Total balance falling to zero over \(plan.payoffMonths ?? 0) months")
            }
        }
    }

    private var orderCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Payoff order").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let ordered = plan.perDebt.sorted { ($0.payoffMonth ?? 9999) < ($1.payoffMonth ?? 9999) }
                ForEach(Array(ordered.enumerated()), id: \.element.id) { idx, r in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Theme.accentSoft).frame(width: 28, height: 28)
                            Text("\(idx + 1)").font(Theme.rounded(13, .bold)).foregroundStyle(Theme.accent)
                        }
                        Text(r.name).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        if let m = r.payoffMonth {
                            Text(Fmt.monthsLabel(m)).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.good)
                        } else {
                            Text("—").foregroundStyle(Theme.inkSoft)
                        }
                    }
                    if idx < ordered.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }

    /// Downsample to keep the chart light at long horizons.
    private func sampled(_ months: [MonthPoint]) -> [MonthPoint] {
        guard months.count > 120 else { return months }
        let stride = Int((Double(months.count) / 120).rounded(.up))
        var out = months.enumerated().filter { $0.offset % stride == 0 }.map(\.element)
        if let last = months.last, out.last?.id != last.id { out.append(last) }
        return out
    }
}

private struct ClosedValue { let lo: Double; let hi: Double }
