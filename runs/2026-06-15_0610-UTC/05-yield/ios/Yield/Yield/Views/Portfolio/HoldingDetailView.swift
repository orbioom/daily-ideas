import SwiftUI
import SwiftData

/// Holding detail: projected income, YoC, current yield, pay schedule, a DRIP mini-projection,
/// logged payments history, and edit. Reads from a live @Bindable model.
struct HoldingDetailView: View {
    @Bindable var holding: Holding
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var showEdit = false
    @State private var showDeleteConfirm = false
    @State private var showLogPayment = false

    private var hidden: Bool { settings.balancesHidden(isPro: isPro) }
    private var code: String { settings.currencyCode }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard
                metricsGrid
                scheduleCard
                dripMiniCard
                historyCard
            }
            .padding(16)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(holding.ticker)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    Button { showLogPayment = true } label: { Label("Log payment", systemImage: "plus.circle") }
                    Button(role: .destructive) { showDeleteConfirm = true } label: {
                        Label("Delete holding", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) { HoldingFormView(mode: .edit(holding)) }
        .sheet(isPresented: $showLogPayment) { LogPaymentView(holding: holding) }
        .confirmationDialog("Delete \(holding.ticker)?",
                            isPresented: $showDeleteConfirm,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteHolding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the holding and its logged payments.")
        }
    }

    // MARK: Hero

    private var heroCard: some View {
        let annual = IncomeEngine.annualIncome(for: holding)
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(holding.sector.color.opacity(0.16))
                        Image(systemName: holding.sector.symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(holding.sector.color)
                    }
                    .frame(width: 46, height: 46)
                    .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(holding.name)
                            .font(Theme.rounded(17, .bold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(holding.sector.label)
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Projected annual income")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    MoneyText(value: annual, code: code, hidden: hidden,
                              font: Theme.rounded(30, .bold), color: Theme.good)
                    Text("≈ \(MoneyFormat.currencyCompact(annual / 12, code: code)) / month")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        .opacity(hidden ? 0 : 1)
                }
            }
        }
    }

    // MARK: Metrics

    private var metricsGrid: some View {
        let yoc = IncomeEngine.yieldOnCost(for: holding)
        let cy = IncomeEngine.currentYield(for: holding)
        let basis = IncomeEngine.costBasis(for: holding)
        let value = IncomeEngine.marketValue(for: holding)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(label: "Yield on cost", value: yoc.map { MoneyFormat.percent($0) } ?? "—", icon: "percent", tint: Theme.accent)
            StatTile(label: "Current yield", value: cy.map { MoneyFormat.percent($0) } ?? "—", icon: "chart.line.uptrend.xyaxis", tint: Theme.good)
            StatTile(label: "Cost basis", value: MoneyFormat.currencyCompact(basis, code: code), icon: "dollarsign.circle", tint: Theme.inkSoft, hidden: hidden)
            StatTile(label: "Market value", value: value.map { MoneyFormat.currencyCompact($0, code: code) } ?? "—", icon: "tag", tint: Theme.inkSoft, hidden: hidden)
        }
    }

    // MARK: Schedule

    private var scheduleCard: some View {
        let per = IncomeEngine.perPaymentIncome(for: holding)
        let next = IncomeEngine.nextPayDate(for: holding)
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Pay schedule")
                row("Frequency", holding.frequency.label)
                row("Months", holding.payCycle.label(for: holding.frequency))
                row("Pay day", "Day \(holding.payDayOfMonth)")
                row("Per payment", hidden ? "••••" : MoneyFormat.currency(per, code: code))
                if let next {
                    row("Next payment", next.formatted(date: .abbreviated, time: .omitted))
                }
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: DRIP mini

    private var dripMiniCard: some View {
        let annual = IncomeEngine.annualIncome(for: holding)
        let yld = IncomeEngine.currentYield(for: holding) ?? IncomeEngine.yieldOnCost(for: holding) ?? 0
        let series = IncomeEngine.dripProjection(startingAnnualIncome: annual,
                                                 portfolioYield: yld,
                                                 annualGrowthRate: settings.defaultGrowthRate,
                                                 years: 10)
        let future = series.last?.annualIncome ?? annual
        return CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Reinvested in 10 years",
                              subtitle: "At \(MoneyFormat.percent(settings.defaultGrowthRate, fractionDigits: 1)) DPS growth, dividends reinvested")
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    MoneyText(value: future, code: code, compact: true, hidden: hidden,
                              font: Theme.rounded(26, .bold), color: Theme.accent)
                    if annual > 0, !hidden {
                        let mult = (future.doubleValue / max(annual.doubleValue, 0.0001))
                        Text(String(format: "%.1f×", mult))
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.good)
                    }
                }
                Text("Projection only — not a forecast or advice.")
                    .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
            }
        }
    }

    // MARK: History

    private var historyCard: some View {
        let payments = holding.payments.sorted { $0.payDate > $1.payDate }
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionHeader(title: "Logged payments")
                    Button { showLogPayment = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Log a payment")
                }
                if payments.isEmpty {
                    Text("No payments logged yet. Tap + to record one as it lands.")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(payments) { p in
                        HStack(spacing: 12) {
                            Image(systemName: p.reinvested ? "arrow.triangle.2.circlepath" : "dollarsign.circle")
                                .font(.system(size: 14))
                                .foregroundStyle(p.reinvested ? Theme.accent : Theme.inkSoft)
                                .frame(width: 20)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(MoneyFormat.currency(p.total, code: code))
                                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Text(p.payDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                            }
                            Spacer()
                            Text("\(MoneyFormat.perShare(p.amountPerShare, code: code))/sh")
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft).monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(MoneyFormat.currency(p.total, code: code)) on \(p.payDate.formatted(date: .abbreviated, time: .omitted))")
                        if p.id != payments.last?.id {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            }
        }
    }

    // MARK: Actions

    private func deleteHolding() {
        context.delete(holding)
        try? context.save()
        Haptics.impact(settings.hapticsEnabled)
        dismiss()
    }
}
