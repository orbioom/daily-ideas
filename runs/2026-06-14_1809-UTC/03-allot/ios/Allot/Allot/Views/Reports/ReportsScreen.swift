import SwiftUI
import SwiftData
import Charts

/// Spending donut, income-vs-expense bars, net-spending trend, and top categories.
/// Full charts are gated behind Pro; free users see a teaser + paywall.
struct ReportsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Account.dateAdded) private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var transactions: [Transaction]

    @State private var monthKey = BudgetEngine.currentMonthKey
    @State private var snapshot: ReportSnapshot = .empty
    @State private var isLoading = true
    @State private var paywall: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isLoading {
                    loadingView
                } else if !snapshot.hasData {
                    EmptyStateView(symbol: "chart.pie",
                                   title: "No reports yet",
                                   message: "Record some income and spending, then come back to see where your money goes.")
                } else {
                    content
                }
            }
            .navigationTitle("Reports")
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
            .task(id: recomputeKey) { await recompute() }
        }
    }

    /// Recompute whenever the month or the underlying data count changes.
    private var recomputeKey: String {
        "\(monthKey)-\(transactions.count)-\(categories.count)-\(accounts.count)"
    }

    @MainActor private func recompute() async {
        isLoading = true
        let snap = ReportSnapshot.build(monthKey: monthKey,
                                        accounts: accounts,
                                        categories: categories,
                                        txns: transactions)
        try? await Task.sleep(nanoseconds: 200_000_000)
        snapshot = snap
        isLoading = false
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Crunching your numbers…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing reports")
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                MonthSwitcher(monthKey: $monthKey, hapticsEnabled: settings.hapticsEnabled)
                summaryCard
                if isPro {
                    donutCard
                    incomeExpenseCard
                    trendCard
                    topCategoriesCard
                } else {
                    proTeaser
                }
            }
            .padding(16)
        }
    }

    // MARK: Cards

    private var summaryCard: some View {
        CardSection(snapshot.monthTitle) {
            HStack {
                summaryTile("Income", snapshot.income, Theme.good)
                Divider().frame(height: 38).overlay(Theme.hairline)
                summaryTile("Spent", snapshot.expense, Theme.ink)
                Divider().frame(height: 38).overlay(Theme.hairline)
                summaryTile("Net", snapshot.net, snapshot.net < -0.005 ? Theme.bad : Theme.good)
            }
        }
    }

    private func summaryTile(_ label: String, _ value: Double, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.inkSoft)
            Text(settings.moneyMasked(value))
                .font(Theme.money(18, .bold)).monospacedDigit()
                .foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(settings.money(value))
    }

    private var donutCard: some View {
        CardSection("Spending by category") {
            if snapshot.slices.isEmpty {
                Text("No spending recorded this month.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(snapshot.slices) { slice in
                    SectorMark(
                        angle: .value("Amount", slice.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(Theme.slice(hue: slice.colorHue))
                    .accessibilityLabel(slice.name)
                    .accessibilityValue(settings.money(slice.amount))
                }
                .frame(height: 220)
                .overlay {
                    VStack(spacing: 2) {
                        Text("Spent").font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        Text(settings.moneyMasked(snapshot.expense))
                            .font(Theme.money(20, .bold)).monospacedDigit().foregroundStyle(Theme.ink)
                    }
                    .accessibilityHidden(true)
                }
            }
        }
    }

    private var incomeExpenseCard: some View {
        CardSection("Income vs. expenses") {
            Chart {
                ForEach(snapshot.monthly) { m in
                    BarMark(x: .value("Month", m.label),
                            y: .value("Amount", m.income))
                        .position(by: .value("Kind", "Income"))
                        .foregroundStyle(Theme.good)
                        .accessibilityLabel("\(m.label) income")
                        .accessibilityValue(settings.money(m.income))
                    BarMark(x: .value("Month", m.label),
                            y: .value("Amount", m.expense))
                        .position(by: .value("Kind", "Expense"))
                        .foregroundStyle(Theme.bad)
                        .accessibilityLabel("\(m.label) expense")
                        .accessibilityValue(settings.money(m.expense))
                }
            }
            .chartForegroundStyleScale(["Income": Theme.good, "Expense": Theme.bad])
            .chartLegend(position: .bottom)
            .frame(height: 200)
        }
    }

    private var trendCard: some View {
        CardSection("Spending trend") {
            Chart(snapshot.trend) { point in
                LineMark(x: .value("Month", point.label),
                         y: .value("Spent", point.netSpending))
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Month", point.label),
                         y: .value("Spent", point.netSpending))
                    .foregroundStyle(Theme.accent.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Month", point.label),
                          y: .value("Spent", point.netSpending))
                    .foregroundStyle(Theme.accent)
                    .accessibilityLabel(point.label)
                    .accessibilityValue(settings.money(point.netSpending))
            }
            .frame(height: 180)
        }
    }

    private var topCategoriesCard: some View {
        CardSection("Top categories") {
            if snapshot.slices.isEmpty {
                Text("Nothing spent yet this month.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                VStack(spacing: 10) {
                    ForEach(snapshot.slices.prefix(5)) { slice in
                        HStack(spacing: 10) {
                            Circle().fill(Theme.slice(hue: slice.colorHue)).frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text("\(slice.emoji) \(slice.name)")
                                .font(Theme.rounded(15)).foregroundStyle(Theme.ink)
                            Spacer()
                            Text(settings.moneyMasked(slice.amount))
                                .font(Theme.money(15, .semibold)).monospacedDigit()
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(slice.name)
                        .accessibilityValue(settings.money(slice.amount))
                    }
                }
            }
        }
    }

    private var proTeaser: some View {
        Button { paywall = .reports } label: {
            CardSection {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        Image(systemName: "lock.fill").font(.system(size: 24)).foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Unlock full Reports")
                                .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                            Text("Spending donut, income vs. expenses, and your spending trend are part of Allot Pro.")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    teaserDonut
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Allot Pro")
    }

    /// A blurred, non-interactive donut hinting at the locked content.
    private var teaserDonut: some View {
        Chart(snapshot.slices.isEmpty ? teaserSlices : snapshot.slices) { slice in
            SectorMark(angle: .value("Amount", slice.amount), innerRadius: .ratio(0.6), angularInset: 1.5)
                .foregroundStyle(Theme.slice(hue: slice.colorHue))
        }
        .frame(height: 150)
        .blur(radius: 6)
        .overlay(Image(systemName: "lock.fill").font(.system(size: 26)).foregroundStyle(Theme.accent))
        .accessibilityHidden(true)
    }

    private var teaserSlices: [ReportSnapshot.CategorySlice] {
        (0..<5).map { i in
            ReportSnapshot.CategorySlice(name: "—", emoji: "", amount: Double(5 - i) * 10,
                                         colorHue: Double(i) / 5.0)
        }
    }
}
