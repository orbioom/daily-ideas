import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]

    @State private var period: StatsPeriod = .all
    @State private var paywallReason: PaywallReason?

    private var sym: String { settings.currencySymbol }
    private var hide: Bool { settings.hideAmounts }

    private var scoped: [Session] { period.filter(sessions) }
    private var engine: StatsEngine { StatsEngine(sessions: scoped) }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(symbol: "chart.bar.xaxis",
                                   title: "No data yet",
                                   message: "Log a few sessions and your analytics — win rate, breakdowns and profit over time — will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            periodPicker
                            summaryRow
                            winRateCard
                            profitOverTimeCard
                            if isPro {
                                monthlyCard
                                breakdownCard(title: "By stake", symbol: "dollarsign.circle", data: engine.byStake)
                                breakdownCard(title: "By game", symbol: "suit.spade", data: engine.byGameType)
                                breakdownCard(title: "By location", symbol: "mappin.circle", data: engine.byLocation)
                            } else {
                                proTeaser
                            }
                            Color.clear.frame(height: 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Analytics")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: $period) {
            ForEach(StatsPeriod.allCases) { p in
                Text(p.rawValue).tag(p)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            StatChip(label: "Profit",
                     value: hide ? "\(sym)••" : Money.string(engine.totalProfit, symbol: sym, signed: true),
                     tint: engine.totalProfit >= 0 ? Theme.good : Theme.bad)
            StatChip(label: "Sessions", value: "\(engine.sessionCount)", tint: Theme.accent)
            StatChip(label: "Hours", value: String(format: "%.0f", engine.totalHours), tint: Theme.accent)
        }
    }

    // MARK: - Win rate gauge

    private var winRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Win rate", systemImage: "target")
            HStack(spacing: 20) {
                Gauge(value: min(1, max(0, engine.winRate / 100))) {
                    Text("Win")
                } currentValueLabel: {
                    Text(Money.percent(engine.winRate))
                        .font(Theme.mono(14, .bold))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Theme.accent)
                .scaleEffect(1.3)
                .frame(width: 80, height: 80)
                .accessibilityLabel("Win rate \(Money.percent(engine.winRate))")

                VStack(alignment: .leading, spacing: 8) {
                    miniStat("Average / session",
                             hide ? "\(sym)••" : Money.string(engine.averageProfit ?? 0, symbol: sym, signed: true))
                    if let roi = engine.tournamentROI {
                        miniStat("Tournament ROI", Money.percent(roi, fractionDigits: 1))
                    }
                    if let sd = engine.standardDeviation {
                        miniStat("Std dev / session",
                                 hide ? "\(sym)••" : Money.string(sd, symbol: sym))
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            Spacer()
            Text(value).font(Theme.mono(13, .semibold)).foregroundStyle(Theme.ink)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Profit over time

    private var profitOverTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Profit over time", systemImage: "chart.line.uptrend.xyaxis")
            let points = engine.cumulativeProfit
            if points.count < 2 {
                emptyChartNote("Not enough sessions in this period yet.")
            } else {
                Chart(points) { p in
                    LineMark(x: .value("Date", p.date),
                             y: .value("Profit", dbl(p.value)))
                        .foregroundStyle(Theme.accent)
                        .interpolationMethod(.monotone)
                    AreaMark(x: .value("Date", p.date),
                             y: .value("Profit", dbl(p.value)))
                        .foregroundStyle(Theme.accent.opacity(0.15))
                        .interpolationMethod(.monotone)
                }
                .chartYAxis { axisMoneyMarks }
                .frame(height: 170)
                .accessibilityLabel("Profit over time chart")
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Monthly bars (Pro)

    private var monthlyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Monthly profit", systemImage: "calendar")
            let months = engine.byMonth
            if months.isEmpty {
                emptyChartNote("No monthly data in this period.")
            } else {
                Chart(months) { m in
                    BarMark(x: .value("Month", m.label),
                            y: .value("Profit", dbl(m.profit)))
                        .foregroundStyle(m.profit >= 0 ? Theme.good : Theme.bad)
                }
                .chartYAxis { axisMoneyMarks }
                .frame(height: 170)
                .accessibilityLabel("Monthly profit bars")
            }
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Generic breakdown (Pro)

    private func breakdownCard(title: String, symbol: String, data: [Breakdown]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: title, systemImage: symbol)
            if data.isEmpty {
                emptyChartNote("No data for this breakdown.")
            } else {
                Chart(data) { b in
                    BarMark(x: .value("Profit", dbl(b.profit)),
                            y: .value("Category", b.label))
                        .foregroundStyle(b.profit >= 0 ? Theme.good : Theme.bad)
                        .annotation(position: .trailing) {
                            Text(hide ? "•" : Money.string(b.profit, symbol: sym, signed: true))
                                .font(Theme.mono(10))
                                .foregroundStyle(Theme.inkSoft)
                        }
                }
                .chartXAxis { axisMoneyMarks }
                .frame(height: CGFloat(max(120, data.count * 38)))
                .accessibilityLabel("\(title) breakdown")
            }
        }
        .padding(16)
        .cardSurface()
    }

    private var proTeaser: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "chart.pie.fill").foregroundStyle(Theme.gold)
                Text("Full breakdowns").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                Spacer()
                ProLockChip()
            }
            Text("Unlock Felt Pro to see profit broken down by stake, game type, location, and month — so you know exactly where your edge is.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Unlock full analytics", systemImage: "lock.open.fill") {
                Haptics.tap(enabled: settings.hapticsEnabled)
                paywallReason = .analytics
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func emptyChartNote(_ text: String) -> some View {
        Text(text)
            .font(Theme.rounded(14))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, minHeight: 110)
    }

    private var axisMoneyMarks: some AxisContent {
        AxisMarks { value in
            AxisGridLine().foregroundStyle(Theme.hairline)
            AxisValueLabel {
                if let d = value.as(Double.self) {
                    Text(hide ? "•" : Money.string(Decimal(d), symbol: sym))
                        .font(Theme.mono(10))
                } else if let s = value.as(String.self) {
                    Text(s).font(Theme.rounded(10))
                }
            }
        }
    }

    private func dbl(_ d: Decimal) -> Double {
        let v = NSDecimalNumber(decimal: d).doubleValue
        return v.isFinite ? v : 0
    }
}
