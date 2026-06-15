import SwiftUI
import SwiftData
import Charts

/// Insights: income by sector (donut), top payers, the goal ring vs your annual target,
/// portfolio yield, and a yield-on-cost distribution across holdings.
struct InsightsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Holding.createdAt, order: .forward) private var holdings: [Holding]

    private var hidden: Bool { settings.balancesHidden(isPro: isPro) }
    private var code: String { settings.currencyCode }

    private var sectors: [SectorIncome] { IncomeEngine.incomeBySector(holdings) }
    private var payers: [PayerIncome] { IncomeEngine.topPayers(holdings, limit: 6) }
    private var annual: Decimal { IncomeEngine.totalAnnualIncome(holdings) }

    var body: some View {
        NavigationStack {
            Group {
                if holdings.isEmpty {
                    EmptyStateView(symbol: "chart.pie",
                                   title: "No insights yet",
                                   message: "Add holdings to see income by sector, top payers, and progress toward your income goal.")
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                goalCard
                sectorCard
                topPayersCard
                yieldCard
            }
            .padding(16)
        }
    }

    // MARK: Goal ring

    private var goalCard: some View {
        let goal = Decimal(max(settings.annualGoal, 0))
        let progress: Double = {
            guard goal > 0 else { return 0 }
            return min(annual.doubleValue / goal.doubleValue, 1)
        }()
        let pyoc = IncomeEngine.portfolioYieldOnCost(holdings)
        return CardView {
            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(Theme.surfaceAlt, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Theme.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(MoneyFormat.percent(progress, fractionDigits: 0))
                            .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                        Text("of goal").font(Theme.rounded(10)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .frame(width: 104, height: 104)
                .accessibilityElement()
                .accessibilityLabel("Income goal progress \(MoneyFormat.percent(progress, fractionDigits: 0))")
                VStack(alignment: .leading, spacing: 8) {
                    Text("Income goal")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    MoneyText(value: annual, code: code, compact: true, hidden: hidden,
                              font: Theme.rounded(22, .bold), color: Theme.good)
                    Text("of \(MoneyFormat.currencyCompact(goal, code: code)) target")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    if let pyoc {
                        Pill(text: "\(MoneyFormat.percent(pyoc)) portfolio YoC", systemImage: "percent")
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: Sector donut

    private var sectorCard: some View {
        let top = IncomeEngine.topPayerConcentration(holdings)
        return CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Income by sector",
                              subtitle: "Top payer is \(MoneyFormat.percent(top, fractionDigits: 0)) of income")
                if sectors.isEmpty {
                    Text("Add holdings with dividends to see sector mix.")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                } else {
                    Chart(sectors) { item in
                        SectorMark(
                            angle: .value("Income", item.amount.doubleValue),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.sector.color)
                        .cornerRadius(3)
                    }
                    .frame(height: 190)
                    .accessibilityLabel("Income share by sector")
                    .accessibilityChartDescriptor(SectorChartDescriptor(sectors: sectors))

                    VStack(spacing: 8) {
                        ForEach(sectors) { item in
                            HStack(spacing: 10) {
                                Circle().fill(item.sector.color).frame(width: 10, height: 10)
                                    .accessibilityHidden(true)
                                Text(item.sector.label)
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(MoneyFormat.percent(item.fraction, fractionDigits: 0))
                                    .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft).monospacedDigit()
                                MoneyText(value: item.amount, code: code, compact: true, hidden: hidden,
                                          font: Theme.rounded(13, .semibold), color: Theme.inkSoft)
                                    .frame(width: 72, alignment: .trailing)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(item.sector.label): \(MoneyFormat.percent(item.fraction, fractionDigits: 0)) of income")
                        }
                    }
                }
            }
        }
    }

    // MARK: Top payers

    private var topPayersCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Top payers")
                ForEach(payers) { p in
                    HStack(spacing: 12) {
                        Text(p.ticker)
                            .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.ink)
                            .frame(width: 56, alignment: .leading)
                        ProgressView(value: maxFraction > 0 ? p.fraction / maxFraction : 0)
                            .tint(Theme.accent)
                        MoneyText(value: p.amount, code: code, compact: true, hidden: hidden,
                                  font: Theme.rounded(13, .semibold), color: Theme.good)
                            .frame(width: 72, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(p.ticker): \(MoneyFormat.percent(p.fraction, fractionDigits: 0)) of income")
                }
            }
        }
    }

    private var maxFraction: Double { payers.map { $0.fraction }.max() ?? 0 }

    // MARK: Yield distribution

    private var yieldCard: some View {
        let points = holdings.compactMap { h -> (String, Double)? in
            guard let y = IncomeEngine.yieldOnCost(for: h) else { return nil }
            return (h.ticker, y)
        }
        .sorted { $0.1 > $1.1 }
        return CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Yield on cost by holding")
                if points.isEmpty {
                    Text("Add cost basis to see yield on cost.")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                } else {
                    Chart(points, id: \.0) { point in
                        BarMark(
                            x: .value("Yield", point.1),
                            y: .value("Ticker", point.0)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .cornerRadius(3)
                        .annotation(position: .trailing) {
                            Text(MoneyFormat.percent(point.1, fractionDigits: 1))
                                .font(Theme.rounded(9, .semibold))
                                .foregroundStyle(Theme.inkSoft)
                        }
                    }
                    .frame(height: CGFloat(points.count) * 28 + 20)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine().foregroundStyle(Theme.hairline)
                            AxisValueLabel {
                                if let d = value.as(Double.self) {
                                    Text(MoneyFormat.percent(d, fractionDigits: 0)).font(Theme.rounded(9))
                                }
                            }
                        }
                    }
                    .accessibilityLabel("Yield on cost for each holding")
                }
            }
        }
    }
}

/// Audio-chart descriptor for VoiceOver on the sector donut.
private struct SectorChartDescriptor: AXChartDescriptorRepresentable {
    let sectors: [SectorIncome]

    func makeChartDescriptor() -> AXChartDescriptor {
        let labels = sectors.map { $0.sector.label }
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Sector",
            range: 0...Double(max(sectors.count - 1, 1)),
            gridlinePositions: []
        ) { value in
            let idx = Int(value.rounded())
            return labels.indices.contains(idx) ? labels[idx] : ""
        }
        let values = sectors.map { $0.amount.doubleValue }
        let maxVal = values.max() ?? 1
        let valueAxis = AXNumericDataAxisDescriptor(
            title: "Income",
            range: 0...(maxVal == 0 ? 1 : maxVal),
            gridlinePositions: []
        ) { String(format: "%.0f", $0) }
        let series = AXDataSeriesDescriptor(
            name: "Income by sector",
            isContinuous: false,
            dataPoints: sectors.enumerated().map { index, item in
                AXDataPoint(x: Double(index), y: item.amount.doubleValue)
            }
        )
        return AXChartDescriptor(
            title: "Income by sector",
            summary: nil,
            xAxis: xAxis,
            yAxis: valueAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
