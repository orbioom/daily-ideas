import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query(sort: \SleepLog.wakeTime, order: .reverse) private var logs: [SleepLog]
    @AppStorage("nocturne.goalHours") private var goalHours = 8.0
    @AppStorage("nocturne.clock24")   private var clock24   = false

    @State private var rangeIndex = 0   // 0 = 14 nights, 1 = 30 nights
    private var rangeOptions = ["14 Nights", "30 Nights"]

    private var rangeCount: Int { rangeIndex == 0 ? 14 : 30 }

    private var slice: [SleepLog] {
        Array(logs.prefix(rangeCount))
    }

    // Reverse slice for chronological chart display (oldest → newest)
    private var chronoSlice: [SleepLog] {
        Array(slice.reversed())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if logs.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar.xaxis",
                        title: "No data yet",
                        message: "Log a few nights and your sleep insights will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Range picker
                            Picker("Range", selection: $rangeIndex) {
                                ForEach(rangeOptions.indices, id: \.self) { i in
                                    Text(rangeOptions[i]).tag(i)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .onChange(of: rangeIndex) { _, _ in Haptics.selection() }
                            .accessibilityLabel("Time range")

                            // Duration bar chart
                            durationBarChartCard

                            // Summary stats
                            summaryStatsCard

                            // Bedtime + wake scatter
                            timingChartCard

                            // Quality distribution
                            qualityDistributionCard

                            // Sleep debt trend
                            debtTrendCard

                            // Tag correlations
                            tagCorrelationCard
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Duration Bar Chart

    private var durationBarChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Duration · Last \(rangeCount) nights")

                Chart {
                    ForEach(chronoSlice) { log in
                        BarMark(
                            x: .value("Date", log.nightDate, unit: .day),
                            y: .value("Hours", log.durationHours)
                        )
                        .foregroundStyle(
                            log.durationHours >= goalHours ? Brand.live : Brand.warn
                        )
                        .cornerRadius(4)
                        .accessibilityLabel(Format.shortDate(log.nightDate))
                        .accessibilityValue("\(Format.duration(log.durationHours))")
                    }

                    // Goal rule line
                    RuleMark(y: .value("Goal", goalHours))
                        .foregroundStyle(Brand.magic.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal \(Format.hoursDecimal(goalHours))")
                                .font(Brand.mono(10))
                                .foregroundStyle(Brand.magic)
                                .padding(.trailing, 4)
                        }
                }
                .chartYScale(domain: 0...(maxDuration + 1.5))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: rangeIndex == 0 ? 2 : 5)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.twoDigits))
                            .font(Brand.mono(9))
                            .foregroundStyle(Brand.text3)
                        AxisGridLine().foregroundStyle(Brand.hairline)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { val in
                        if let h = val.as(Double.self) {
                            AxisValueLabel {
                                Text(Format.hoursDecimal(h))
                                    .font(Brand.mono(9))
                                    .foregroundStyle(Brand.text3)
                            }
                            AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.5))
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Sleep duration bar chart over last \(rangeCount) nights")
            }
        }
        .padding(.horizontal, 20)
    }

    private var maxDuration: Double {
        slice.map(\.durationHours).max() ?? goalHours
    }

    // MARK: - Summary Stats

    private var summaryStatsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Eyebrow(text: "Summary · \(rangeCount) nights")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCell(
                        label: "Avg Duration",
                        value: SleepEngine.averageDuration(logs: slice).map { Format.duration($0) } ?? "—"
                    )
                    statCell(
                        label: "Avg Quality",
                        value: SleepEngine.averageQuality(logs: slice).map { String(format: "%.1f★", $0) } ?? "—"
                    )
                    statCell(
                        label: "Avg Awakenings",
                        value: SleepEngine.averageAwakenings(logs: slice).map { String(format: "%.1f", $0) } ?? "—"
                    )
                    statCell(
                        label: "Avg Bedtime",
                        value: SleepEngine.averageBedtimeMinutes(logs: slice).map {
                            // Undo the +720 shift applied by bedtimeMinutesOfDay
                            let unshifted = ($0 - 720 + 1440) % 1440
                            return Format.clockFromMinutes(unshifted, use24h: clock24)
                        } ?? "—"
                    )
                    statCell(
                        label: "Avg Wake",
                        value: SleepEngine.averageWaketimeMinutes(logs: slice).map {
                            Format.clockFromMinutes($0, use24h: clock24)
                        } ?? "—"
                    )
                    statCell(
                        label: "Regularity",
                        value: "\(SleepEngine.regularityScore(logs: slice, lastN: rangeCount))/100"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func statCell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(Brand.mono(9, weight: .medium))
                .foregroundStyle(Brand.text3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timing Chart (Bedtime + Waketime scatter)

    private var timingChartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Bedtime & Wake Times")

                Chart {
                    ForEach(chronoSlice) { log in
                        PointMark(
                            x: .value("Date", log.nightDate, unit: .day),
                            y: .value("Bed (h)", log.bedTime.minutesOfDay / 60.0)
                        )
                        .foregroundStyle(Brand.info.opacity(0.8))
                        .symbolSize(50)
                        .accessibilityLabel("Bed \(Format.shortDate(log.nightDate))")
                        .accessibilityValue(Format.clock(log.bedTime, use24h: clock24))

                        PointMark(
                            x: .value("Date", log.nightDate, unit: .day),
                            y: .value("Wake (h)", log.wakeTime.minutesOfDay / 60.0)
                        )
                        .foregroundStyle(Brand.live.opacity(0.8))
                        .symbolSize(50)
                        .accessibilityLabel("Wake \(Format.shortDate(log.nightDate))")
                        .accessibilityValue(Format.clock(log.wakeTime, use24h: clock24))
                    }
                }
                .chartYScale(domain: 0...26)
                .chartYAxis {
                    AxisMarks(values: [0, 6, 12, 18, 24]) { val in
                        if let h = val.as(Double.self) {
                            AxisValueLabel {
                                Text(hourLabel(h))
                                    .font(Brand.mono(9))
                                    .foregroundStyle(Brand.text3)
                            }
                            AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.4))
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: rangeIndex == 0 ? 2 : 5)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.twoDigits))
                            .font(Brand.mono(9))
                            .foregroundStyle(Brand.text3)
                        AxisGridLine().foregroundStyle(Brand.hairline)
                    }
                }
                .frame(height: 160)

                // Legend
                HStack(spacing: 16) {
                    legendDot(color: Brand.info, text: "Bedtime")
                    legendDot(color: Brand.live, text: "Wake Time")
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Bedtime and wake time scatter chart")
    }

    private func legendDot(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
    }

    private func hourLabel(_ h: Double) -> String {
        let hour = Int(h) % 24
        if clock24 { return String(format: "%02d:00", hour) }
        switch hour {
        case 0:  return "12am"
        case 12: return "12pm"
        default: return hour < 12 ? "\(hour)am" : "\(hour - 12)pm"
        }
    }

    // MARK: - Quality Distribution

    private var qualityDistributionCard: some View {
        let dist = SleepEngine.qualityDistribution(logs: slice)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Quality Distribution")

                Chart {
                    ForEach(1...5, id: \.self) { q in
                        BarMark(
                            x: .value("Quality", Format.qualityLabel(q)),
                            y: .value("Nights", dist[q] ?? 0)
                        )
                        .foregroundStyle(qualityColor(q))
                        .cornerRadius(5)
                        .accessibilityLabel(Format.qualityLabel(q))
                        .accessibilityValue("\(dist[q] ?? 0) nights")
                    }
                }
                .chartYAxis {
                    AxisMarks { val in
                        if let n = val.as(Double.self) {
                            AxisValueLabel {
                                Text(String(Int(n)))
                                    .font(Brand.mono(9))
                                    .foregroundStyle(Brand.text3)
                            }
                            AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.4))
                        }
                    }
                }
                .frame(height: 120)
                .accessibilityLabel("Quality distribution chart")
            }
        }
        .padding(.horizontal, 20)
    }

    private func qualityColor(_ q: Int) -> Color {
        switch q {
        case 1: return Brand.danger
        case 2: return Brand.warn
        case 3: return Brand.text3
        case 4: return Brand.live
        default: return Brand.magic
        }
    }

    // MARK: - Debt Trend

    private var debtTrendCard: some View {
        // Rolling 14-night debt computed at each point in time
        let points = debtTrendPoints()
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Sleep Debt Trend")

                if points.isEmpty {
                    Text("Not enough data for trend")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                } else {
                    Chart {
                        ForEach(points, id: \.date) { point in
                            AreaMark(
                                x: .value("Date", point.date, unit: .day),
                                yStart: .value("Debt", 0),
                                yEnd: .value("Debt", max(0, point.debt))
                            )
                            .foregroundStyle(Brand.warn.opacity(0.18))

                            LineMark(
                                x: .value("Date", point.date, unit: .day),
                                y: .value("Debt", max(0, point.debt))
                            )
                            .foregroundStyle(Brand.warn)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)
                            .accessibilityLabel(Format.shortDate(point.date))
                            .accessibilityValue("\(Format.hoursDecimal(point.debt)) debt")
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { val in
                            if let h = val.as(Double.self) {
                                AxisValueLabel {
                                    Text(Format.hoursDecimal(h))
                                        .font(Brand.mono(9))
                                        .foregroundStyle(Brand.text3)
                                }
                                AxisGridLine().foregroundStyle(Brand.hairline.opacity(0.4))
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: rangeIndex == 0 ? 2 : 5)) { _ in
                            AxisValueLabel(format: .dateTime.day().month(.twoDigits))
                                .font(Brand.mono(9))
                                .foregroundStyle(Brand.text3)
                            AxisGridLine().foregroundStyle(Brand.hairline)
                        }
                    }
                    .frame(height: 130)
                    .accessibilityLabel("Sleep debt trend chart")
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private struct DebtPoint {
        let date: Date
        let debt: Double
    }

    private func debtTrendPoints() -> [DebtPoint] {
        guard slice.count >= 2 else { return [] }
        // For each log (chronological order), compute the rolling debt up to that day
        let chrono: [SleepLog] = logs.reversed()
        var points: [DebtPoint] = []
        let windowSize = min(14, chrono.count)

        for i in (windowSize - 1)..<chrono.count {
            let window = Array(chrono[max(0, i - windowSize + 1)...i])
            let reversedWindow: [SleepLog] = window.reversed()
            let debt = SleepEngine.rollingDebt(logs: reversedWindow, targetHours: goalHours, window: windowSize)
            points.append(DebtPoint(date: chrono[i].nightDate, debt: max(0, debt)))
        }
        // Limit to rangeCount most recent
        return Array(points.suffix(rangeCount))
    }

    // MARK: - Tag Correlations

    private var tagCorrelationCard: some View {
        let correlations = SleepEngine.tagCorrelations(logs: logs)
        return GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Tag Effect on Duration")

                if correlations.isEmpty {
                    Text("Not enough tag data")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                } else {
                    VStack(spacing: 8) {
                        ForEach(correlations, id: \.tag) { item in
                            tagCorrelationRow(item)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
    }

    private func tagCorrelationRow(_ item: (tag: String, withTag: Double, withoutTag: Double)) -> some View {
        let delta = item.withTag - item.withoutTag
        let color: Color = delta >= 0.25 ? Brand.live : (delta <= -0.25 ? Brand.danger : Brand.text3)
        return HStack {
            Text(item.tag)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.duration(item.withTag))
                    .font(Brand.mono(13, weight: .semibold))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 3) {
                    Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text(Format.hoursDecimal(abs(delta)))
                        .font(Brand.mono(11))
                }
                .foregroundStyle(color)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.tag): avg \(Format.duration(item.withTag)) with tag, \(delta >= 0 ? "up" : "down") \(Format.hoursDecimal(abs(delta))) vs without")
    }
}

// MARK: - Date helper

private extension Date {
    var minutesOfDay: Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: self)
        return Double((c.hour ?? 0) * 60 + (c.minute ?? 0))
    }
}
