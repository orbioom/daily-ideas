import SwiftUI
import SwiftData
import Charts

/// Trends: full Performance Management Chart (selectable range), weekly TSS bars,
/// and a time-in-zone distribution. All charts carry accessibility summaries.
struct TrendsView: View {
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]

    @State private var range: ChartRange = .ninety
    @State private var isComputing = false
    @State private var series: [LoadEngine.DayPoint] = []
    @State private var weekly: [LoadEngine.WeekBucket] = []
    @State private var zones: [LoadEngine.ZoneTime] = []

    private var rangedSeries: [LoadEngine.DayPoint] {
        Array(series.suffix(range.days))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if rides.isEmpty {
                    EmptyStateView(icon: "chart.xyaxis.line",
                                   title: "No trends yet",
                                   message: "Log a few rides and your Performance Management Chart, weekly load and zone distribution will appear here.")
                        .padding(.top, 60)
                } else if isComputing {
                    loadingState
                } else {
                    content
                }
            }
            .navigationTitle("Trends")
            .background(Brand.pageBackground)
        }
        .task(id: rideSignature) { await recompute() }
    }

    private var rideSignature: Int {
        var hasher = Hasher()
        hasher.combine(rides.count)
        for r in rides {
            hasher.combine(r.id)
            hasher.combine(r.durationMin)
            hasher.combine(r.normalizedPower)
            hasher.combine(r.tssManual)
            hasher.combine(r.ftpAtTime)
            hasher.combine(r.entryRaw)
            hasher.combine(r.date)
        }
        return hasher.finalize()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            pmcCard
            weeklyCard
            zoneCard
        }
        .padding(20)
    }

    // MARK: PMC

    private var pmcCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SectionTitle(text: "Performance Management")
                    Spacer()
                }
                Picker("Range", selection: $range) {
                    ForEach(ChartRange.allCases) { r in Text(r.label).tag(r) }
                }
                .pickerStyle(.segmented)
                .onChange(of: range) { _, _ in Haptics.selection() }

                if rangedSeries.count > 1 {
                    PMCChart(points: rangedSeries, showTSB: true, height: 240)
                    LegendRow()
                    if let last = rangedSeries.last {
                        HStack(spacing: 12) {
                            miniStat("Fitness", Format.int(last.ctl), Brand.live)
                            miniStat("Fatigue", Format.int(last.atl), Brand.warn)
                            miniStat("Form", Format.signedInt(last.tsb),
                                     LoadEngine.formStatus(tsb: last.tsb).color)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    Text("Not enough days in range yet.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private func miniStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(color)
            Text(label.uppercased()).font(Brand.mono(8, weight: .medium)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Weekly TSS

    private var weeklyCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Weekly load · last 12 weeks")
                Chart(weekly) { week in
                    BarMark(
                        x: .value("Week", week.weekStart, unit: .weekOfYear),
                        y: .value("TSS", week.tss)
                    )
                    .foregroundStyle(Brand.inkGradient)
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine().foregroundStyle(Brand.hairline)
                        AxisValueLabel().font(Brand.mono(9))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 3)) { _ in
                        AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.5))
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day()).font(Brand.mono(9))
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Weekly training load bar chart")
                .accessibilityValue(weeklySummary)
            }
        }
    }

    private var weeklySummary: String {
        guard !weekly.isEmpty else { return "No data" }
        let total = weekly.reduce(0) { $0 + $1.tss }
        let avg = total / Double(weekly.count)
        let peak = weekly.max { $0.tss < $1.tss }
        return "Average \(Format.int(avg)) TSS per week. Peak \(Format.int(peak?.tss ?? 0)) TSS."
    }

    // MARK: Time in zone

    private var zoneCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle(text: "Time in zone · power rides")
                let total = zones.reduce(0) { $0 + $1.minutes }
                if total == 0 {
                    Text("Log power-based rides to see your zone distribution.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    Chart(zones) { z in
                        BarMark(
                            x: .value("Minutes", z.minutes),
                            y: .value("Zone", z.name)
                        )
                        .foregroundStyle(z.color)
                        .cornerRadius(4)
                        .annotation(position: .trailing) {
                            if z.minutes > 0 {
                                Text(Format.duration(z.minutes))
                                    .font(Brand.mono(9)).foregroundStyle(Brand.text3)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.5))
                            AxisValueLabel().font(Brand.mono(9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { _ in
                            AxisValueLabel().font(Brand.mono(9))
                        }
                    }
                    .frame(height: 220)
                    .accessibilityLabel("Time in zone distribution")
                    .accessibilityValue(zoneSummary(total: total))
                }
            }
        }
    }

    private func zoneSummary(total: Int) -> String {
        let top = zones.max { $0.minutes < $1.minutes }
        guard let top, total > 0 else { return "No data" }
        let pct = Int((Double(top.minutes) / Double(total) * 100).rounded())
        return "Most time in \(top.name): \(Format.duration(top.minutes)), \(pct) percent of \(Format.duration(total)) total."
    }

    // MARK: States & compute

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text("Building your trends…")
                .font(.subheadline).foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    @MainActor
    private func recompute() async {
        isComputing = true
        let inputs = rides.map { RideInput(date: $0.date, tss: $0.tss,
                                           np: $0.normalizedPower, ftp: $0.ftpAtTime,
                                           durationMin: $0.durationMin, entryPower: $0.entry == .power) }
        let result = await Task.detached(priority: .userInitiated) { () -> ([LoadEngine.DayPoint], [LoadEngine.WeekBucket], [LoadEngine.ZoneTime]) in
            let proxies = inputs.map { $0.proxyRide() }
            return (LoadEngine.series(rides: proxies),
                    LoadEngine.weeklyTSS(rides: proxies, weeks: 12),
                    LoadEngine.timeInZone(rides: proxies))
        }.value
        series = result.0
        weekly = result.1
        zones = result.2
        isComputing = false
    }
}

enum ChartRange: String, CaseIterable, Identifiable {
    case fortyTwo, ninety, oneEighty
    var id: String { rawValue }
    var days: Int {
        switch self {
        case .fortyTwo: return 42
        case .ninety: return 90
        case .oneEighty: return 180
        }
    }
    var label: String {
        switch self {
        case .fortyTwo: return "42d"
        case .ninety: return "90d"
        case .oneEighty: return "180d"
        }
    }
}
