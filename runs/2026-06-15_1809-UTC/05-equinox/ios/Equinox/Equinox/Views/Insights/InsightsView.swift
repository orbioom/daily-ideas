import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var paywallReason: PaywallReason?
    @State private var isComputing = true
    @State private var computed: Computed?

    /// Window respects the free-tier history limit.
    private var window: Int { isPro ? 84 : Pro.freeHistoryDays }

    /// Snapshot of all engine outputs so the body doesn't recompute on every redraw.
    private struct Computed {
        let hotFlash: [InsightsEngine.DayValue]
        let rolling: [InsightsEngine.DayValue]
        let trend: InsightsEngine.Trend
        let domains: [InsightsEngine.DomainSeries]
        let mood: [InsightsEngine.DayValue]
        let sleep: [InsightsEngine.DayValue]
        let top: [InsightsEngine.SymptomRank]
        let correlation: InsightsEngine.SleepCorrelation
        let cycle: InsightsEngine.CycleInfo
        let summary: InsightsEngine.Summary
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if allLogs.isEmpty {
                    EmptyStateView(symbol: "chart.xyaxis.line",
                                   title: "Your insights will grow here",
                                   message: "Log a few days and Equinox will chart your hot-flash trends, symptom domains, and cycle changes.")
                        .padding(.top, 40)
                } else if isComputing || computed == nil {
                    computingView
                } else if let c = computed {
                    content(c)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
            .task(id: logsFingerprint) { await compute() }
        }
    }

    /// Cheap fingerprint so we only recompute when data actually changes.
    private var logsFingerprint: String {
        "\(allLogs.count)-\(isPro)-\(allLogs.first?.date.timeIntervalSince1970 ?? 0)-\(allLogs.first?.hotFlashCount ?? 0)"
    }

    private var computingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Computing your patterns…")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Computing your patterns")
    }

    @ViewBuilder
    private func content(_ c: Computed) -> some View {
        VStack(spacing: 18) {
            trendCard(c)
            hotFlashChart(c)
            stageCard(c.cycle)
            if isPro {
                domainChart(c)
                moodSleepChart(c)
                correlationCard(c.correlation)
            } else {
                lockedProCard
            }
            topSymptomsCard(c)
            doctorReportCard(c)
            footer
        }
        .padding(16)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Trend summary

    private func trendCard(_ c: Computed) -> some View {
        let t = c.trend
        let (symbol, color, word): (String, Color, String) = {
            switch t.direction {
            case .up: return ("arrow.up.right", Theme.bad, "more than last week")
            case .down: return ("arrow.down.right", Theme.good, "fewer than last week")
            case .flat: return ("arrow.right", Theme.inkSoft, "about the same as last week")
            }
        }()
        return VStack(spacing: 12) {
            HStack(spacing: 14) {
                StatTile(value: String(format: "%.1f", c.summary.avgHotFlashesPerDay),
                         label: "avg flashes / day", systemImage: "thermometer.sun.fill")
                StatTile(value: "\(Int(t.current))",
                         label: "flashes this week", systemImage: "calendar")
            }
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(color)
                Text("\(Int(abs(t.delta))) \(word)")
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous).fill(Theme.surfaceAlt))
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Hot-flash chart

    private func hotFlashChart(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Hot flashes per day", systemImage: "thermometer.sun.fill")
            Text("Bars are daily counts; the line is your 7-day average.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            Chart {
                ForEach(c.hotFlash) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Flashes", point.value)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.55))
                }
                ForEach(c.rolling) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("7-day avg", point.value)
                    )
                    .foregroundStyle(Theme.accentDeep)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Hot flashes per day chart with seven day average line")
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: - Stage card

    private func stageCard(_ cycle: InsightsEngine.CycleInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Where you are", systemImage: "circle.hexagongrid.fill")
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.accentSoft).frame(width: 52, height: 52)
                    Image(systemName: "leaf.fill").foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(cycle.stage.rawValue)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    if let d = cycle.daysSinceLastPeriod {
                        Text("\(d) days since last period")
                            .font(Theme.rounded(12))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }
            Text(cycle.stage.explanation)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if let gap = cycle.longestGap {
                Text("Longest recent gap between periods: \(gap) days.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
            Text("Informational, not a diagnosis. Bring big changes to your clinician.")
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(18)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    // MARK: - Domain chart (Pro)

    private func domainChart(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Symptom domains over time", systemImage: "square.stack.3d.up.fill")
            Text("Daily severity totals per Greene-style domain.")
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
            Chart {
                ForEach(c.domains) { series in
                    ForEach(series.points) { point in
                        LineMark(
                            x: .value("Day", point.date, unit: .day),
                            y: .value("Severity", point.value)
                        )
                        .foregroundStyle(by: .value("Domain", series.domain.rawValue))
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
            .chartForegroundStyleScale(domainColorScale)
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 200)
            .accessibilityLabel("Symptom severity by domain over time")
        }
        .padding(18)
        .cardSurface()
    }

    private var domainColorScale: KeyValuePairs<String, Color> {
        [
            SymptomDomain.vasomotor.rawValue: Theme.accent,
            SymptomDomain.psychological.rawValue: Theme.dusk,
            SymptomDomain.somatic.rawValue: Theme.good,
            SymptomDomain.sexual.rawValue: Theme.warn
        ]
    }

    // MARK: - Mood & sleep (Pro)

    private func moodSleepChart(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Mood & sleep", systemImage: "moon.stars.fill")
            Chart {
                ForEach(c.mood) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Rating", point.value),
                        series: .value("Metric", "Mood")
                    )
                    .foregroundStyle(Theme.accent)
                    .symbol(.circle)
                }
                ForEach(c.sleep) { point in
                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Rating", point.value),
                        series: .value("Metric", "Sleep")
                    )
                    .foregroundStyle(Theme.dusk)
                    .symbol(.square)
                }
            }
            .chartYScale(domain: 1.0...5.0)
            .chartYAxis { AxisMarks(position: .leading, values: [1.0, 2.0, 3.0, 4.0, 5.0]) }
            .frame(height: 180)
            .accessibilityLabel("Mood and sleep ratings over time")
            HStack(spacing: 16) {
                legendDot(Theme.accent, "Mood")
                legendDot(Theme.dusk, "Sleep")
                Spacer()
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Correlation (Pro)

    private func correlationCard(_ corr: InsightsEngine.SleepCorrelation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Sleep & hot flashes", systemImage: "bed.double.fill")
            if corr.hasSignal {
                let more = corr.difference >= 0
                Text(more
                     ? "On poor-sleep days you averaged \(fmt(corr.poorSleepAvgHotFlashes)) hot flashes, versus \(fmt(corr.goodSleepAvgHotFlashes)) on restful days."
                     : "Interestingly, your hot flashes were similar or lower on poor-sleep days (\(fmt(corr.poorSleepAvgHotFlashes)) vs \(fmt(corr.goodSleepAvgHotFlashes))).")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    StatTile(value: fmt(corr.poorSleepAvgHotFlashes), label: "poor-sleep days", systemImage: "zzz", tint: Theme.bad)
                    StatTile(value: fmt(corr.goodSleepAvgHotFlashes), label: "restful days", systemImage: "sparkles", tint: Theme.good)
                }
            } else {
                Text("Log a few more nights of sleep quality to reveal how it relates to your hot flashes.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .cardSurface()
    }

    private func fmt(_ v: Double) -> String { String(format: "%.1f", v) }

    // MARK: - Locked Pro card

    private var lockedProCard: some View {
        Button {
            paywallReason = .insights
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionHeader(title: "Deeper insights", systemImage: "lock.fill")
                    ProLockChip()
                }
                Text("Unlock domain severity trends, mood-and-sleep charts, and your sleep-hot-flash correlation with Equinox Pro.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .cardSurface()
        }
        .buttonStyle(PressableScale())
    }

    // MARK: - Top symptoms

    private func topSymptomsCard(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your top symptoms", systemImage: "list.number")
            if c.top.isEmpty {
                Text("No symptoms logged yet — add a few on Today to see them ranked here.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                Chart {
                    ForEach(c.top) { rank in
                        BarMark(
                            x: .value("Score", rank.score),
                            y: .value("Symptom", rank.name)
                        )
                        .foregroundStyle(Theme.accent.gradient)
                        .annotation(position: .trailing) {
                            Text("\(rank.daysPresent)d")
                                .font(Theme.rounded(10))
                                .foregroundStyle(Theme.inkFaint)
                        }
                    }
                }
                .chartXAxis(.hidden)
                .frame(height: CGFloat(c.top.count) * 38 + 20)
                .accessibilityLabel("Top symptoms ranked by frequency and severity")
            }
        }
        .padding(18)
        .cardSurface()
    }

    // MARK: - Doctor report

    private func doctorReportCard(_ c: Computed) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Doctor report", systemImage: "doc.text.fill")
                if !isPro { ProLockChip() }
            }
            Text("A clean summary of your range, hot flashes, top symptoms, and cycle — ready to share with your clinician.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if isPro {
                DoctorReportCard(summary: c.summary)
                    .frame(maxWidth: .infinity)
                ShareLink(item: DoctorReportText.make(from: c.summary)) {
                    Label("Share summary", systemImage: "square.and.arrow.up")
                        .font(Theme.rounded(15, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.heroGradient))
                }
                .accessibilityLabel("Share doctor summary")
            } else {
                PrimaryButton(title: "Unlock doctor report", systemImage: "lock.open.fill") {
                    paywallReason = .doctorReport
                }
            }
        }
        .padding(18)
        .cardSurface()
    }

    private var footer: some View {
        Text("Equinox insights are informational and never a diagnosis.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    // MARK: - Compute

    private func compute() async {
        isComputing = true
        let logs = allLogs
        let win = window
        // Yield once so the UI can present the computing state before the (cheap, pure) work.
        await Task.yield()
        let engine = InsightsEngine(logs: logs)
        let result = Computed(
            hotFlash: engine.hotFlashSeries(lastDays: win),
            rolling: engine.hotFlashRollingAverage(lastDays: win),
            trend: engine.hotFlashWeekOverWeek(),
            domains: engine.domainSeverityTrends(lastDays: win),
            mood: engine.moodSeries(lastDays: win),
            sleep: engine.sleepSeries(lastDays: win),
            top: engine.topSymptoms(limit: 6),
            correlation: engine.sleepHotFlashCorrelation(),
            cycle: engine.cycleInfo(),
            summary: engine.summary()
        )
        computed = result
        isComputing = false
    }
}
