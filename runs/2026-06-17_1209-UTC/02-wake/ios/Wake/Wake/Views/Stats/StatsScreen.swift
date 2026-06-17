import SwiftUI
import SwiftData
import Charts

/// Stats: lifetime totals, distance over time, stroke distribution, pace trend.
/// Advanced charts (pace trend, SWOLF context) are gated behind Pro.
struct StatsScreen: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue

    @State private var period: StatsPeriod = .quarter
    @State private var result: StatsResult?
    @State private var isLoading = false
    @State private var paywallReason: PaywallReason?

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isPro {
                        Button {
                            paywallReason = .stats
                        } label: {
                            Label("Pro", systemImage: "crown.fill")
                                .font(Theme.rounded(13, .semibold))
                        }
                    }
                }
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
        .task(id: dataSignature) { await recompute() }
    }

    private var dataSignature: String {
        let count = sessions.count
        let dist = Int(sessions.reduce(0) { $0 + $1.totalDistanceMeters })
        return "\(count)-\(dist)-\(period.rawValue)"
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.accent)
                Text("Crunching your swims…")
                    .font(.callout)
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Computing statistics")
        } else if let result, !result.isEmpty {
            ScrollView {
                VStack(spacing: 16) {
                    periodPicker
                    summaryGrid(result)
                    milestoneCard(result)
                    weeklyChart(result)
                    strokeChart(result)
                    if isPro {
                        paceChart(result)
                    } else {
                        proTeaser
                    }
                }
                .padding(20)
            }
        } else {
            EmptyStateView(symbol: "chart.xyaxis.line",
                           title: "No stats yet",
                           message: "Log a few swims and your distance, pace, and stroke trends will appear here.")
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

    private func summaryGrid(_ r: StatsResult) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(title: "Total distance", value: fmt.distance(r.totalDistanceMeters), symbol: "ruler")
            StatTile(title: "Swims", value: "\(r.sessionCount)", symbol: "figure.pool.swim")
            StatTile(title: "Avg pace",
                     value: r.averagePacePer100 > 0 ? fmt.pacePer100(r.averagePacePer100) : "—",
                     symbol: "speedometer")
            StatTile(title: "Longest swim", value: fmt.distance(r.longestSwimMeters), symbol: "arrow.up.right")
            StatTile(title: "Pool time", value: UnitFormatter.clock(Double(r.totalDurationSeconds)), symbol: "clock")
            StatTile(title: "Week streak", value: "\(r.currentStreakWeeks)", symbol: "flame.fill", tint: Theme.warn)
        }
    }

    private func milestoneCard(_ r: StatsResult) -> some View {
        let lengths = StatsEngine.olympicLengths(r.totalDistanceMeters)
        let channel = StatsEngine.channelPercent(r.totalDistanceMeters)
        return SectionCard(title: "Milestone", symbol: "trophy.fill") {
            VStack(alignment: .leading, spacing: 6) {
                Text("That's \(lengths) lengths of an Olympic pool.")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(format: "You're %.1f%% of the way across the English Channel.", channel))
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func weeklyChart(_ r: StatsResult) -> some View {
        SectionCard(title: "Weekly distance", symbol: "chart.bar.fill") {
            if r.weeklyDistance.isEmpty {
                emptyChartNote
            } else {
                Chart(r.weeklyDistance) { point in
                    BarMark(
                        x: .value("Week", point.weekStart, unit: .weekOfYear),
                        y: .value("Distance", fmt.distanceValue(point.distanceMeters))
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .chartYAxisLabel(unit.shortUnit)
                .frame(height: 200)
                .accessibilityLabel("Weekly distance bar chart in \(unit.label)")
            }
        }
    }

    private func strokeChart(_ r: StatsResult) -> some View {
        SectionCard(title: "Distance by stroke", symbol: "chart.pie.fill") {
            if r.strokeSlices.isEmpty {
                emptyChartNote
            } else {
                Chart(r.strokeSlices) { slice in
                    SectorMark(
                        angle: .value("Distance", slice.distanceMeters),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.stroke.hue)
                    .cornerRadius(3)
                }
                .frame(height: 200)
                .accessibilityLabel("Stroke distribution donut chart")

                strokeLegend(r.strokeSlices)
            }
        }
    }

    private func strokeLegend(_ slices: [StrokeSlice]) -> some View {
        let total = max(1, slices.reduce(0) { $0 + $1.distanceMeters })
        return VStack(spacing: 6) {
            ForEach(slices) { slice in
                HStack(spacing: 8) {
                    Circle().fill(slice.stroke.hue).frame(width: 10, height: 10)
                    Text(slice.stroke.label)
                        .font(.footnote)
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(fmt.distance(slice.distanceMeters)) · \(Int((slice.distanceMeters / total) * 100))%")
                        .font(.footnote)
                        .foregroundStyle(Theme.inkSoft)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func paceChart(_ r: StatsResult) -> some View {
        SectionCard(title: "Pace per 100 trend", symbol: "speedometer") {
            if r.paceTrend.count < 2 {
                Text("Log a couple more swims to see your pace trend.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Chart(r.paceTrend) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Seconds/100", point.secondsPer100)
                    )
                    .foregroundStyle(Theme.accent)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Seconds/100", point.secondsPer100)
                    )
                    .foregroundStyle(Theme.accentDeep)
                }
                .chartYAxisLabel("sec / 100\(unit.shortUnit)")
                .frame(height: 200)
                .accessibilityLabel("Pace per 100 trend line, lower is faster")
            }
        }
    }

    private var proTeaser: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock pace trends & SWOLF")
                .font(Theme.rounded(18, .semibold))
                .foregroundStyle(Theme.ink)
            Text("See whether your pace per 100 is improving over time, and analyze SWOLF efficiency — part of Wake Pro.")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "See Wake Pro", systemImage: "crown.fill") {
                paywallReason = .stats
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var emptyChartNote: some View {
        Text("Not enough data yet.")
            .font(.footnote)
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        let snapshot = sessions
        let chosen = period
        try? await Task.sleep(nanoseconds: 300_000_000)
        result = StatsEngine.compute(sessions: snapshot, period: chosen)
        isLoading = false
    }
}
