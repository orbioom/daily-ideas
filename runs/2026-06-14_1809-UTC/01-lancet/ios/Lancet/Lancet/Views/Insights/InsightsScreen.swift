import SwiftUI
import SwiftData
import Charts

/// Insights: A1C, time-in-range, GMI, variability, charts. Full version is Pro.
struct InsightsScreen: View {
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Reading.date, order: .reverse) private var readings: [Reading]

    @State private var snapshot: GlucoseSnapshot = .empty
    @State private var isLoading = true
    @State private var paywall: PaywallReason?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if isLoading {
                    loadingView
                } else if snapshot.count == 0 {
                    EmptyStateView(symbol: "chart.xyaxis.line",
                                   title: "No insights yet",
                                   message: "Log a few readings and your A1C estimate, time-in-range and trends will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headlineCard
                            tirCard
                            if isPro {
                                trendCard
                                tirDonutCard
                                hourlyCard
                                byContextCard
                                variabilityCard
                            } else {
                                proLock
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
            .sheet(item: $paywall) { r in PaywallView(reason: r) }
            .task(id: readings.count) { await recompute() }
            .task(id: settings.unitRaw) { await recompute() }
            .refreshable { await recompute() }
        }
    }

    @MainActor
    private func recompute() async {
        isLoading = true
        let snap = GlucoseEngine.compute(readings: readings,
                                         low: settings.safeLow,
                                         high: settings.safeHigh)
        try? await Task.sleep(nanoseconds: 250_000_000)
        snapshot = snap
        isLoading = false
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView().controlSize(.large)
            Text("Crunching your readings…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing insights")
    }

    // MARK: Always-free headline (A1C + averages)

    private var headlineCard: some View {
        CardSection("Your estimate") {
            HStack(spacing: 12) {
                metricTile(String(format: "%.1f%%", snapshot.estimatedA1C), "Est. A1C", Theme.accent)
                metricTile(String(format: "%.1f%%", snapshot.gmi), "GMI", Theme.elevated)
                metricTile(settings.formatValue(snapshot.averageMgdl), "Avg", Theme.inRange)
            }
            Text("A1C is estimated from your average glucose. It is not a substitute for a lab test.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func metricTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(color)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var tirCard: some View {
        CardSection("Time in range") {
            TimeInRangeBar(slices: snapshot.rangeSlices, height: 20)
            VStack(spacing: 6) {
                statRow(.inRange, snapshot.timeInRange)
                statRow(.low, snapshot.pctLow)
                statRow(.high, snapshot.pctHigh)
            }
            Text("Based on \(snapshot.count) readings · \(String(format: "%.1f", snapshot.readingsPerDay)) per day")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
        }
    }

    private func statRow(_ band: GlucoseBand, _ fraction: Double) -> some View {
        HStack {
            Circle().fill(band.color).frame(width: 10, height: 10).accessibilityHidden(true)
            Text(band.rawValue).font(Theme.rounded(13)).foregroundStyle(Theme.ink)
            Spacer()
            Text("\(Int((fraction * 100).rounded()))%")
                .font(Theme.rounded(13, .semibold)).foregroundStyle(Theme.inkSoft).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(band.rawValue): \(Int((fraction * 100).rounded())) percent")
    }

    // MARK: Pro charts

    private var trendCard: some View {
        CardSection("Glucose over time") {
            Chart {
                // Shaded target band.
                RectangleMark(
                    yStart: .value("Low", settings.unit.value(fromMgdl: settings.safeLow)),
                    yEnd: .value("High", settings.unit.value(fromMgdl: settings.safeHigh))
                )
                .foregroundStyle(Theme.inRange.opacity(0.12))

                ForEach(snapshot.points) { p in
                    PointMark(
                        x: .value("Date", p.date),
                        y: .value("Glucose", settings.unit.value(fromMgdl: p.mgdl))
                    )
                    .foregroundStyle(p.band.color)
                    .symbolSize(28)
                }
            }
            .chartYAxisLabel(settings.unit.label)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: false)
                }
            }
            .frame(height: 200)
            .accessibilityLabel("Glucose readings over time with shaded target band")
        }
    }

    private var tirDonutCard: some View {
        CardSection("Range breakdown") {
            if snapshot.rangeSlices.isEmpty {
                Text("Not enough data.").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(snapshot.rangeSlices) { slice in
                    SectorMark(
                        angle: .value("Share", slice.pct),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.band.color)
                    .cornerRadius(3)
                    .accessibilityLabel(slice.band.rawValue)
                    .accessibilityValue("\(Int((slice.pct * 100).rounded())) percent")
                }
                .frame(height: 200)
                .chartLegend(position: .bottom)
            }
        }
    }

    private var hourlyCard: some View {
        CardSection("Average by hour") {
            if snapshot.hourlyAverages.isEmpty {
                Text("Not enough data.").font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(snapshot.hourlyAverages) { h in
                    BarMark(
                        x: .value("Hour", h.label),
                        y: .value("Average", settings.unit.value(fromMgdl: h.averageMgdl))
                    )
                    .foregroundStyle(settings.band(for: h.averageMgdl).color.gradient)
                    .accessibilityLabel(h.label)
                    .accessibilityValue("\(settings.formatValue(h.averageMgdl)) average, \(h.count) readings")
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) {
                        AxisValueLabel().font(Theme.rounded(9))
                    }
                }
                .frame(height: 170)
            }
        }
    }

    private var byContextCard: some View {
        CardSection("Average by context") {
            Chart(snapshot.byContextAverage) { entry in
                BarMark(
                    x: .value("Average", settings.unit.value(fromMgdl: entry.averageMgdl)),
                    y: .value("Context", entry.context.label)
                )
                .foregroundStyle(settings.band(for: entry.averageMgdl).color.gradient)
                .annotation(position: .trailing) {
                    Text(settings.formatValue(entry.averageMgdl))
                        .font(Theme.rounded(10, .bold))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel(entry.context.label)
                .accessibilityValue("\(settings.formatValue(entry.averageMgdl)) average from \(entry.count) readings")
            }
            .chartXAxisLabel(settings.unit.label)
            .frame(height: CGFloat(max(snapshot.byContextAverage.count, 1)) * 34 + 24)
        }
    }

    private var variabilityCard: some View {
        CardSection("Variability & excursions") {
            HStack(spacing: 12) {
                metricTile(String(format: "%.0f%%", snapshot.variabilityCV), "CV", cvColor)
                metricTile("\(snapshot.hypoCount)", "Lows", Theme.low)
                metricTile("\(snapshot.hyperCount)", "Highs", Theme.high)
            }
            Text(cvBlurb)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var cvColor: Color {
        snapshot.variabilityCV <= 36 ? Theme.inRange : Theme.elevated
    }

    private var cvBlurb: String {
        if snapshot.variabilityCV <= 36 {
            return "A coefficient of variation at or below 36% is considered stable. Yours looks steady."
        }
        return "A coefficient of variation above 36% suggests swings worth discussing with your care team."
    }

    private var proLock: some View {
        Button { paywall = .insights } label: {
            CardSection {
                HStack(spacing: 14) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Unlock full Insights")
                            .font(Theme.rounded(16, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("Trend charts, range donut, hourly patterns, by-context averages and variability are part of Lancet Pro.")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Pro upgrade screen")
    }
}
