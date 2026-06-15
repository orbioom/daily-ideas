import SwiftUI
import SwiftData
import Charts

/// Income Calendar: a forward 12-month projected-income bar chart, a per-month breakdown,
/// and an upcoming-payments feed derived from each holding's schedule.
struct CalendarScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Holding.createdAt, order: .forward) private var holdings: [Holding]

    @State private var selectedMonthIndex: Int?

    private var hidden: Bool { settings.balancesHidden(isPro: isPro) }
    private var code: String { settings.currencyCode }

    private var months: [MonthIncome] {
        let now = Date()
        let comps = Calendar.current.dateComponents([.month, .year], from: now)
        let m = comps.month ?? 1
        let y = comps.year ?? 2025
        return IncomeEngine.forwardMonthlyIncome(holdings, startMonth: m, startYear: y)
    }

    private var upcoming: [UpcomingPayment] {
        holdings.compactMap { h -> UpcomingPayment? in
            guard let date = IncomeEngine.nextPayDate(for: h) else { return nil }
            let amount = IncomeEngine.perPaymentIncome(for: h)
            guard amount > 0 else { return nil }
            return UpcomingPayment(id: h.id, ticker: h.ticker, name: h.name, date: date, amount: amount)
        }
        .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if holdings.isEmpty {
                    EmptyStateView(symbol: "calendar",
                                   title: "No calendar yet",
                                   message: "Add holdings to see your projected income mapped across the next 12 months.")
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Calendar")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryCard
                chartCard
                breakdownCard
                upcomingCard
            }
            .padding(16)
        }
    }

    // MARK: Summary

    private var summaryCard: some View {
        let total = months.reduce(Decimal(0)) { $0 + $1.amount }
        let peak = months.max { $0.amount < $1.amount }
        return CardView {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Next 12 months")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    MoneyText(value: total, code: code, compact: true, hidden: hidden,
                              font: Theme.rounded(26, .bold), color: Theme.good)
                }
                Spacer()
                if let peak {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Biggest month")
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        Text(hidden ? "\(peak.shortLabel)" : "\(peak.shortLabel) · \(MoneyFormat.currencyCompact(peak.amount, code: code))")
                            .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink).monospacedDigit()
                    }
                }
            }
        }
    }

    // MARK: Chart

    private var chartCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Projected monthly income",
                              subtitle: hidden ? "Balances hidden" : "Tap a bar for the month total")
                Chart(months) { month in
                    BarMark(
                        x: .value("Month", month.shortLabel),
                        y: .value("Income", month.amount.doubleValue)
                    )
                    .foregroundStyle(selectedMonthIndex == month.monthIndex ? Theme.good : Theme.accent.opacity(0.85))
                    .cornerRadius(4)
                    .annotation(position: .top) {
                        if selectedMonthIndex == month.monthIndex, !hidden {
                            Text(MoneyFormat.currencyCompact(month.amount, code: code))
                                .font(Theme.rounded(10, .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel {
                            if let d = value.as(Double.self), !hidden {
                                Text(MoneyFormat.currencyCompact(Decimal(d), code: code))
                                    .font(Theme.rounded(9))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let s = value.as(String.self) {
                                Text(s).font(Theme.rounded(9))
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
                                guard let plotAnchor = proxy.plotFrame else { return }
                                let origin = geo[plotAnchor].origin
                                if let label: String = proxy.value(atX: location.x - origin.x) {
                                    selectedMonthIndex = months.first { $0.shortLabel == label }?.monthIndex
                                    Haptics.select(settings.hapticsEnabled)
                                }
                            }
                    }
                }
                .accessibilityLabel("Projected monthly income for the next 12 months")
                .accessibilityChartDescriptor(MonthlyChartDescriptor(months: months, code: code, hidden: hidden))
            }
        }
    }

    // MARK: Breakdown

    private var breakdownCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Month by month")
                ForEach(months) { m in
                    HStack {
                        Text(m.shortLabel)
                            .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.ink)
                            .frame(width: 42, alignment: .leading)
                        ProgressView(value: barFraction(m))
                            .tint(Theme.accent)
                        MoneyText(value: m.amount, code: code, compact: true, hidden: hidden,
                                  font: Theme.rounded(13, .semibold), color: Theme.inkSoft)
                            .frame(width: 76, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(m.shortLabel): \(hidden ? "hidden" : MoneyFormat.currency(m.amount, code: code))")
                }
            }
        }
    }

    private func barFraction(_ m: MonthIncome) -> Double {
        let maxVal = months.map { $0.amount.doubleValue }.max() ?? 0
        guard maxVal > 0 else { return 0 }
        return min(m.amount.doubleValue / maxVal, 1)
    }

    // MARK: Upcoming feed

    private var upcomingCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Upcoming payments")
                if upcoming.isEmpty {
                    Text("No upcoming payments scheduled.")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                } else {
                    ForEach(upcoming.prefix(8)) { p in
                        HStack(spacing: 12) {
                            VStack(spacing: 0) {
                                Text(p.date.formatted(.dateTime.month(.abbreviated)))
                                    .font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.accent)
                                Text(p.date.formatted(.dateTime.day()))
                                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                            }
                            .frame(width: 40)
                            .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(p.ticker).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Text(p.name).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint).lineLimit(1)
                            }
                            Spacer()
                            MoneyText(value: p.amount, code: code, compact: true, hidden: hidden,
                                      font: Theme.rounded(15, .bold), color: Theme.good)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(p.ticker) pays \(hidden ? "a hidden amount" : MoneyFormat.currency(p.amount, code: code)) on \(p.date.formatted(date: .abbreviated, time: .omitted))")
                        if p.id != upcoming.prefix(8).last?.id {
                            Divider().overlay(Theme.hairline)
                        }
                    }
                }
            }
        }
    }
}

/// Audio-chart descriptor for VoiceOver on the monthly income chart.
private struct MonthlyChartDescriptor: AXChartDescriptorRepresentable {
    let months: [MonthIncome]
    let code: String
    let hidden: Bool

    func makeChartDescriptor() -> AXChartDescriptor {
        let labels = months.map { $0.shortLabel }
        let xAxis = AXNumericDataAxisDescriptor(
            title: "Month",
            range: 0...Double(max(months.count - 1, 1)),
            gridlinePositions: []
        ) { value in
            let idx = Int(value.rounded())
            return labels.indices.contains(idx) ? labels[idx] : ""
        }
        let values = months.map { $0.amount.doubleValue }
        let maxVal = values.max() ?? 1
        let yAxis = AXNumericDataAxisDescriptor(
            title: "Projected income",
            range: 0...(maxVal == 0 ? 1 : maxVal),
            gridlinePositions: []
        ) { value in
            self.hidden ? "hidden" : MoneyFormat.currencyCompact(Decimal(value), code: self.code)
        }
        let series = AXDataSeriesDescriptor(
            name: "Monthly income",
            isContinuous: false,
            dataPoints: months.map {
                AXDataPoint(x: Double($0.monthIndex), y: $0.amount.doubleValue)
            }
        )
        return AXChartDescriptor(
            title: "Projected monthly income",
            summary: nil,
            xAxis: xAxis,
            yAxis: yAxis,
            additionalAxes: [],
            series: [series]
        )
    }
}
