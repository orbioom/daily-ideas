import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query(sort: \Property.createdAt) private var properties: [Property]

    @State private var months = 6
    @State private var showPaywall = false
    @State private var isLoading = false
    @State private var flows: [MonthlyFlow] = []
    @State private var breakdown: [CategorySlice] = []
    @State private var noiData: [PropertyNOI] = []

    var body: some View {
        NavigationStack {
            Group {
                if !pro.isPro {
                    proTeaser
                } else if properties.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .screenBackground()
            .navigationTitle("Reports")
            .toolbar {
                if pro.isPro && !properties.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        ShareLink(
                            item: CSVDocument(text: CSVExporter.transactionsCSV(for: properties), filename: "deed-transactions.csv"),
                            preview: SharePreview("Deed Transactions", image: Image(systemName: "tablecells"))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export transactions CSV")
                    }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task(id: months) { await recompute() }
            .onChange(of: properties.count) { _, _ in
                Task { await recompute() }
            }
        }
    }

    private var proTeaser: some View {
        ScrollView {
            VStack(spacing: 20) {
                ProTeaser(
                    title: "Unlock Reports",
                    message: "Visualize income vs. expense, cash-flow trends, and expense breakdowns — plus CSV export for taxes.",
                    onUnlock: { showPaywall = true }
                )
                teaserPreview
            }
            .padding(16)
        }
    }

    private var teaserPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.inkSoft)
            Chart {
                ForEach(samplePreview) { item in
                    BarMark(
                        x: .value("Month", item.label),
                        y: .value("Net", NSDecimalNumber(decimal: item.net).doubleValue)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.5))
                }
            }
            .frame(height: 160)
            .chartYAxis(.hidden)
            .blur(radius: 3)
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
        }
        .cardSurface()
    }

    private var samplePreview: [MonthlyFlow] {
        (1...6).map { i in
            MonthlyFlow(monthStart: Date(), label: "M\(i)", income: Decimal(2000 + i * 200), expense: Decimal(800 + i * 60))
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            systemImage: "chart.bar.xaxis",
            title: "No data to chart yet",
            message: "Add properties with transactions and rent to see income, cash flow, and expense reports here."
        )
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 18) {
                periodPicker
                if isLoading {
                    loadingCard
                } else {
                    incomeExpenseChart
                    cashFlowChart
                    expenseDonut
                    noiChart
                    exportCard
                }
            }
            .padding(16)
        }
    }

    private var periodPicker: some View {
        SegmentedPills(
            options: [(3, "3 mo"), (6, "6 mo"), (12, "12 mo")],
            selection: $months
        ) {
            Haptics.selection(enabled: settings.hapticsEnabled)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Crunching the numbers…")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardSurface()
    }

    // MARK: Charts

    private var incomeExpenseChart: some View {
        chartCard(title: "Income vs. expense", subtitle: "By month") {
            Chart {
                ForEach(flows) { flow in
                    BarMark(
                        x: .value("Month", flow.label),
                        y: .value("Amount", NSDecimalNumber(decimal: flow.income).doubleValue)
                    )
                    .position(by: .value("Kind", "Income"))
                    .foregroundStyle(Theme.good)

                    BarMark(
                        x: .value("Month", flow.label),
                        y: .value("Amount", NSDecimalNumber(decimal: flow.expense).doubleValue)
                    )
                    .position(by: .value("Kind", "Expense"))
                    .foregroundStyle(Theme.bad)
                }
            }
            .chartForegroundStyleScale(["Income": Theme.good, "Expense": Theme.bad])
            .frame(height: 200)
            .accessibilityLabel("Income versus expense by month")
            .accessibilityValue(incomeExpenseSummary)
        }
    }

    private var cashFlowChart: some View {
        chartCard(title: "Cash-flow trend", subtitle: "Net per month") {
            Chart {
                ForEach(flows) { flow in
                    let net = NSDecimalNumber(decimal: flow.net).doubleValue
                    AreaMark(
                        x: .value("Month", flow.label),
                        y: .value("Net", net)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.18))
                    LineMark(
                        x: .value("Month", flow.label),
                        y: .value("Net", net)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Month", flow.label),
                        y: .value("Net", net)
                    )
                    .foregroundStyle(Theme.accent)
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Net cash flow trend by month")
            .accessibilityValue("Total net \(Money.format(ReportEngine.totalNet(flows), currencyCode: settings.currencyCode)) over \(months) months")
        }
    }

    private var expenseDonut: some View {
        chartCard(title: "Expense breakdown", subtitle: "By category") {
            if breakdown.isEmpty {
                Text("No expenses in this period.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 14) {
                    Chart(breakdown) { slice in
                        SectorMark(
                            angle: .value("Amount", NSDecimalNumber(decimal: slice.amount).doubleValue),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", slice.category.rawValue))
                        .cornerRadius(3)
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Expense breakdown by category")
                    .accessibilityValue(breakdownSummary)

                    legend
                }
            }
        }
    }

    private var legend: some View {
        let total = breakdown.reduce(Decimal(0)) { $0 + $1.amount }
        return VStack(spacing: 6) {
            ForEach(breakdown.prefix(6)) { slice in
                let pct = total > 0 ? Percent.format(slice.amount / total, fractionDigits: 0) : "—"
                HStack(spacing: 8) {
                    Image(systemName: slice.category.systemImage)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 18)
                        .accessibilityHidden(true)
                    Text(slice.category.rawValue)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(Money.format(slice.amount, currencyCode: settings.currencyCode))
                        .font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(pct)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkFaint)
                        .frame(width: 40, alignment: .trailing)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var noiChart: some View {
        chartCard(title: "NOI by property", subtitle: "Annual, trailing 12 mo") {
            if noiData.isEmpty {
                Text("No properties to compare.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(noiData) { item in
                    BarMark(
                        x: .value("NOI", NSDecimalNumber(decimal: item.noi).doubleValue),
                        y: .value("Property", item.name)
                    )
                    .foregroundStyle(Color(hex: UInt(bitPattern: item.colorHex) & 0xFFFFFF))
                    .cornerRadius(4)
                }
                .frame(height: max(140, CGFloat(noiData.count) * 44))
                .accessibilityLabel("Net operating income by property")
                .accessibilityValue(noiSummary)
            }
        }
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)
            Text("Download a spreadsheet-ready CSV for your accountant or tax filing.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 12) {
                ShareLink(
                    item: CSVDocument(text: CSVExporter.transactionsCSV(for: properties), filename: "deed-transactions.csv"),
                    preview: SharePreview("Transactions", image: Image(systemName: "tablecells"))
                ) {
                    Label("Transactions", systemImage: "list.bullet.rectangle")
                        .font(Theme.rounded(14, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .foregroundStyle(Theme.ink)
                }
                ShareLink(
                    item: CSVDocument(text: CSVExporter.rentRollCSV(for: properties), filename: "deed-rent-roll.csv"),
                    preview: SharePreview("Rent Roll", image: Image(systemName: "tablecells"))
                ) {
                    Label("Rent roll", systemImage: "calendar")
                        .font(Theme.rounded(14, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: Theme.radiusS, style: .continuous))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .cardSurface()
    }

    private func chartCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            content()
        }
        .cardSurface()
    }

    // MARK: Accessibility summaries

    private var incomeExpenseSummary: String {
        let income = flows.reduce(Decimal(0)) { $0 + $1.income }
        let expense = flows.reduce(Decimal(0)) { $0 + $1.expense }
        return "Income \(Money.format(income, currencyCode: settings.currencyCode)), expense \(Money.format(expense, currencyCode: settings.currencyCode))"
    }

    private var breakdownSummary: String {
        breakdown.prefix(3).map { "\($0.category.rawValue) \(Money.format($0.amount, currencyCode: settings.currencyCode))" }.joined(separator: ", ")
    }

    private var noiSummary: String {
        noiData.prefix(3).map { "\($0.name) \(Money.format($0.noi, currencyCode: settings.currencyCode))" }.joined(separator: ", ")
    }

    // MARK: Compute

    @MainActor
    private func recompute() async {
        isLoading = true
        // Yield so the spinner can render for heavier portfolios.
        await Task.yield()
        let snapshot = properties
        let m = months
        let pct = settings.closingCostPct
        flows = ReportEngine.monthlyFlows(for: snapshot, months: m)
        breakdown = ReportEngine.expenseBreakdown(for: snapshot, months: m)
        noiData = ReportEngine.noiByProperty(for: snapshot, closingCostPct: pct)
        isLoading = false
    }
}
