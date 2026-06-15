import SwiftUI
import SwiftData

/// Portfolio: header summary (annual income, monthly avg, portfolio yield), sortable holdings
/// list with per-row income contribution + YoC, swipe-to-delete, add, and empty state.
struct PortfolioScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Holding.createdAt, order: .forward) private var holdings: [Holding]

    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var sort: SortField = .income

    enum SortField: String, CaseIterable, Identifiable {
        case income = "Annual income"
        case yoc = "Yield on cost"
        case ticker = "Ticker"
        case shares = "Shares"
        var id: String { rawValue }
    }

    private var hidden: Bool { settings.balancesHidden(isPro: isPro) }
    private var code: String { settings.currencyCode }

    private var sortedHoldings: [Holding] {
        switch sort {
        case .income:
            return holdings.sorted { IncomeEngine.annualIncome(for: $0) > IncomeEngine.annualIncome(for: $1) }
        case .yoc:
            return holdings.sorted { (IncomeEngine.yieldOnCost(for: $0) ?? 0) > (IncomeEngine.yieldOnCost(for: $1) ?? 0) }
        case .ticker:
            return holdings.sorted { $0.ticker < $1.ticker }
        case .shares:
            return holdings.sorted { $0.shares > $1.shares }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if holdings.isEmpty {
                    EmptyStateView(symbol: "chart.bar.doc.horizontal",
                                   title: "Build your portfolio",
                                   message: "Add a dividend-paying holding and Yield will project your income, yields, and payout calendar.",
                                   actionTitle: "Add a holding") { startAdd() }
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !holdings.isEmpty { sortMenu }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { startAdd() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add holding")
                }
            }
            .sheet(isPresented: $showAdd) { HoldingFormView(mode: .add) }
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .holdingLimit) }
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(SortField.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort holdings")
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                header
                if let slots = Pro.remainingSlots(currentCount: holdings.count, isPro: isPro), slots <= 3 {
                    freeTierBanner(slots)
                }
                ForEach(sortedHoldings) { holding in
                    NavigationLink {
                        HoldingDetailView(holding: holding)
                    } label: {
                        HoldingRow(holding: holding, hidden: hidden, code: code)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { delete(holding) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    // MARK: Header

    private var header: some View {
        let annual = IncomeEngine.totalAnnualIncome(holdings)
        let monthly = IncomeEngine.averageMonthlyIncome(holdings)
        let yoc = IncomeEngine.portfolioYieldOnCost(holdings)
        return CardView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected annual income")
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                    MoneyText(value: annual, code: code, hidden: hidden,
                              font: Theme.rounded(34, .bold), color: Theme.ink)
                }
                Divider().overlay(Theme.hairline)
                HStack(spacing: 12) {
                    headerStat("Monthly avg",
                               MoneyFormat.currencyCompact(monthly, code: code),
                               "calendar")
                    headerStat("Yield on cost",
                               yoc.map { MoneyFormat.percent($0) } ?? "—",
                               "percent")
                    headerStat("Holdings", "\(holdings.count)", "number")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func headerStat(_ label: String, _ value: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(label == "Monthly avg" && hidden ? "••••" : value)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func freeTierBanner(_ slots: Int) -> some View {
        Button { showPaywall = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill").foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(slots == 0 ? "Free portfolio full" : "\(slots) free holding\(slots == 1 ? "" : "s") left")
                        .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                    Text("Go Pro for an unlimited portfolio")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint).font(.system(size: 12))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.accentSoft))
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func startAdd() {
        if Pro.canAddHolding(currentCount: holdings.count, isPro: isPro) {
            showAdd = true
        } else {
            Haptics.warning(settings.hapticsEnabled)
            showPaywall = true
        }
    }

    private func delete(_ holding: Holding) {
        context.delete(holding)
        try? context.save()
        Haptics.impact(settings.hapticsEnabled)
    }
}

/// One holding row in the portfolio list.
private struct HoldingRow: View {
    let holding: Holding
    let hidden: Bool
    let code: String

    var body: some View {
        let annual = IncomeEngine.annualIncome(for: holding)
        let yoc = IncomeEngine.yieldOnCost(for: holding)
        return CardView(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(holding.sector.color.opacity(0.16))
                    Image(systemName: holding.sector.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(holding.sector.color)
                }
                .frame(width: 40, height: 40)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(holding.ticker)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(MoneyFormat.shares(holding.shares)) sh · \(holding.frequency.label)")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    MoneyText(value: annual, code: code, compact: true, hidden: hidden,
                              font: Theme.rounded(16, .bold), color: Theme.good)
                    Text(yoc.map { "\(MoneyFormat.percent($0)) YoC" } ?? "—")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(holding.ticker), \(holding.name), annual income \(hidden ? "hidden" : MoneyFormat.currency(annual, code: code))")
        .accessibilityHint("Opens holding details")
    }
}
