import SwiftUI
import SwiftData
import Charts

/// Three Swift Charts: sleep-duration trend, cumulative debt trend, and bedtime
/// consistency scatter. Window is selectable (14 / 30 nights).
struct TrendsView: View {
    @Query(sort: \SleepLog.night, order: .reverse) private var logs: [SleepLog]
    @Query private var settingsList: [SleepSettings]

    @State private var window: Int = 14

    private var settings: SleepSettings? { settingsList.first }
    private var goal: Double { settings?.goalHours ?? 8.0 }
    private var use24h: Bool { settings?.use24HourClock ?? false }

    private var windowed: [SleepLog] {
        SleepEngine.nights(logs: logs, window: window, now: .now, calendar: .current)
            .sorted { $0.night < $1.night }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DriftBackground()
                if logs.isEmpty {
                    EmptyStateView(
                        symbol: "chart.xyaxis.line",
                        title: "No trends yet",
                        message: "Log a few nights and your sleep patterns will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            windowPicker
                            durationChart
                            debtChart
                            consistencyChart
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Trends")
        }
    }

    private var windowPicker: some View {
        Picker("Window", selection: $window) {
            Text("14 nights").tag(14)
            Text("30 nights").tag(30)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Duration trend

    private var durationChart: some View {
        ChartCard(
            title: "Sleep duration",
            subtitle: "Hours in bed vs your \(Format.duration(goal)) goal",
            symbol: "bed.double.fill",
            tint: Theme.night
        ) {
            if windowed.isEmpty {
                emptyChart
            } else {
                Chart {
                    RuleMark(y: .value("Goal", goal))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.textSecondary.opacity(0.6))
                        .annotation(position: .top, alignment: .leading) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    ForEach(windowed) { log in
                        BarMark(
                            x: .value("Night", log.night, unit: .day),
                            y: .value("Hours", log.durationHours)
                        )
                        .foregroundStyle(log.durationHours >= goal ? Theme.good : Theme.night)
                        .cornerRadius(3)
                    }
                }
                .chartYScale(domain: 0...11)
                .chartYAxisLabel("hours")
                .frame(height: 200)
                .accessibilityLabel("Sleep duration bar chart, last \(window) nights")
            }
        }
    }

    // MARK: - Debt trend

    private var debtChart: some View {
        let series = SleepEngine.debtSeries(logs: logs, goalHours: goal, window: window, now: .now)
        return ChartCard(
            title: "Sleep debt",
            subtitle: "Cumulative hours owed over the window",
            symbol: "hourglass",
            tint: Theme.warn
        ) {
            if series.isEmpty {
                emptyChart
            } else {
                Chart {
                    ForEach(series, id: \.night) { point in
                        AreaMark(
                            x: .value("Night", point.night, unit: .day),
                            y: .value("Debt", point.debt)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [Theme.warn.opacity(0.35), Theme.warn.opacity(0.02)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        LineMark(
                            x: .value("Night", point.night, unit: .day),
                            y: .value("Debt", point.debt)
                        )
                        .foregroundStyle(Theme.warn)
                        .interpolationMethod(.monotone)
                    }
                }
                .chartYAxisLabel("hours owed")
                .frame(height: 180)
                .accessibilityLabel("Cumulative sleep debt line chart, last \(window) nights")
            }
        }
    }

    // MARK: - Bedtime consistency

    private var consistencyChart: some View {
        ChartCard(
            title: "Bedtime consistency",
            subtitle: "Each dot is a night's lights-out time",
            symbol: "waveform.path.ecg",
            tint: Theme.dusk
        ) {
            if windowed.isEmpty {
                emptyChart
            } else {
                Chart {
                    ForEach(windowed) { log in
                        PointMark(
                            x: .value("Night", log.night, unit: .day),
                            y: .value("Bedtime", bedtimeHourValue(log.bedTime))
                        )
                        .foregroundStyle(Theme.dusk)
                        .symbolSize(60)
                    }
                }
                .chartYScale(domain: 20...28)
                .chartYAxis {
                    AxisMarks(values: [20, 22, 24, 26, 28]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let raw = value.as(Double.self) {
                                Text(hourLabel(raw))
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Bedtime consistency scatter plot, last \(window) nights. Consistency score \(SleepEngine.consistencyScore(logs: logs, window: window, now: .now)).")
            }
        }
    }

    /// Maps a bedtime to a 20...28 hour scale so post-midnight bedtimes plot above 24.
    private func bedtimeHourValue(_ date: Date) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60.0
        // Evenings 18:00-23:59 → 18-24; early morning 0-5 → 24-29.
        return h < 12 ? h + 24 : h
    }

    private func hourLabel(_ raw: Double) -> String {
        let h = Int(raw) % 24
        let comps = DateComponents(hour: h)
        let date = Calendar.current.date(from: comps) ?? .now
        return Format.clock(date, use24h: use24h)
    }

    private var emptyChart: some View {
        Text("Not enough data in this window yet.")
            .font(.footnote)
            .foregroundStyle(Theme.textSecondary)
            .frame(height: 120)
            .frame(maxWidth: .infinity)
    }
}

/// Reusable titled container for a chart.
private struct ChartCard<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .driftCard()
    }
}
