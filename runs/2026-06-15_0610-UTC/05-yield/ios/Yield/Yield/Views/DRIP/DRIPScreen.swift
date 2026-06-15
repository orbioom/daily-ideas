import SwiftUI
import SwiftData
import Charts

/// DRIP Projector (Pro): sliders for years + dividend-growth rate compound your current
/// income forward, charting future annual income. Pro-gated with a clear locked state.
struct DRIPScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Holding.createdAt, order: .forward) private var holdings: [Holding]

    @State private var years: Double = 20
    @State private var growth: Double = 0.06
    @State private var didInit = false
    @State private var showPaywall = false

    private var hidden: Bool { settings.balancesHidden(isPro: isPro) }
    private var code: String { settings.currencyCode }

    private var annual: Decimal { IncomeEngine.totalAnnualIncome(holdings) }
    private var portfolioYield: Double { IncomeEngine.portfolioYieldOnCost(holdings) ?? 0 }

    private var series: [DripYear] {
        IncomeEngine.dripProjection(startingAnnualIncome: annual,
                                    portfolioYield: portfolioYield,
                                    annualGrowthRate: growth,
                                    years: Int(years.rounded()))
    }

    var body: some View {
        NavigationStack {
            Group {
                if !isPro {
                    lockedState
                } else if holdings.isEmpty {
                    EmptyStateView(symbol: "arrow.triangle.2.circlepath",
                                   title: "Nothing to compound yet",
                                   message: "Add holdings to project years of dividend reinvestment and growth.")
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("DRIP")
            .sheet(isPresented: $showPaywall) { PaywallView(reason: .drip) }
        }
        .onAppear {
            if !didInit { growth = settings.defaultGrowthRate; didInit = true }
        }
    }

    // MARK: Locked

    private var lockedState: some View {
        ScrollView {
            VStack(spacing: 18) {
                EmptyStateView(symbol: "lock.fill",
                               title: "DRIP Projector is a Pro feature",
                               message: "Model years of dividend reinvestment and DPS growth to see where your income could be heading.")
                PrimaryButton(title: "See Yield Pro", systemImage: "crown.fill") {
                    showPaywall = true
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                resultCard
                chartCard
                controlsCard
                assumptionsCard
            }
            .padding(16)
        }
    }

    private var resultCard: some View {
        let future = series.last?.annualIncome ?? annual
        let mult = annual > 0 ? future.doubleValue / max(annual.doubleValue, 0.0001) : 0
        return CardView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Projected income in \(Int(years.rounded())) years")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    MoneyText(value: future, code: code, compact: true, hidden: hidden,
                              font: Theme.rounded(32, .bold), color: Theme.accent)
                    if annual > 0, !hidden {
                        Text(String(format: "%.1f×", mult))
                            .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.good)
                    }
                }
                Text("From \(MoneyFormat.currencyCompact(annual, code: code)) today, reinvesting at \(MoneyFormat.percent(portfolioYield)) with \(MoneyFormat.percent(growth, fractionDigits: 1)) DPS growth.")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(hidden ? 0.5 : 1)
            }
        }
    }

    private var chartCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Income growth path")
                Chart(series) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Income", point.annualIncome.doubleValue)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Year", point.year),
                        y: .value("Income", point.annualIncome.doubleValue)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.14))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let d = value.as(Double.self), !hidden {
                                Text(MoneyFormat.currencyCompact(Decimal(d), code: code)).font(Theme.rounded(9))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisValueLabel {
                            if let y = value.as(Int.self) {
                                Text("\(y)y").font(Theme.rounded(9))
                            }
                        }
                    }
                }
                .accessibilityLabel("Projected annual income over \(Int(years.rounded())) years")
            }
        }
    }

    private var controlsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Years").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(Int(years.rounded()))").font(Theme.mono(14, .semibold)).foregroundStyle(Theme.accent)
                    }
                    Slider(value: $years, in: 1...40, step: 1) {
                        Text("Years")
                    }
                    .tint(Theme.accent)
                    .accessibilityValue("\(Int(years.rounded())) years")
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Annual DPS growth").font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                        Spacer()
                        Text(MoneyFormat.percent(growth, fractionDigits: 1)).font(Theme.mono(14, .semibold)).foregroundStyle(Theme.accent)
                    }
                    Slider(value: $growth, in: 0...0.15, step: 0.005) {
                        Text("Growth rate")
                    }
                    .tint(Theme.accent)
                    .accessibilityValue(MoneyFormat.percent(growth, fractionDigits: 1))
                }
            }
        }
    }

    private var assumptionsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "How this works")
                Text("Each year, dividends are reinvested at your portfolio yield-on-cost (buying more income), and dividend-per-share grows at the rate you set. Compounding both forward gives the path above.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("A simplified model for exploration — not a forecast, guarantee, or financial advice.")
                    .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
