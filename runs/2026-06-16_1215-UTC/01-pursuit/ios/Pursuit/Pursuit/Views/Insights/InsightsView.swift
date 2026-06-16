import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore

    @Query private var applications: [Application]

    @State private var showingPaywall = false

    private var engine: PipelineEngine {
        PipelineEngine(applications: applications, weeklyGoal: settings.weeklyGoal, staleAfterDays: settings.staleAfterDays)
    }

    private var hasData: Bool { engine.total > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if !hasData {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No insights yet",
                        message: "Add a few applications and your response, interview and offer trends will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            goalAndRates
                            if pro.isPro {
                                weeklyChart
                                funnelChart
                                sourceChart
                                donutChart
                                timeToResponseCard
                            } else {
                                proUpsell
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Insights")
            .toolbar {
                if pro.isPro && hasData {
                    ToolbarItem(placement: .topBarTrailing) {
                        CSVShareLink(applications: applications) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Export CSV")
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(reason: "Unlock the full Insights dashboard and CSV export.")
            }
        }
    }

    // MARK: - Always-visible summary (free)

    private var goalAndRates: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ProgressRing(
                    progress: engine.weeklyGoalProgress,
                    lineWidth: 12,
                    centerLabel: "\(engine.thisWeekCount)/\(engine.weeklyGoal)",
                    centerSub: "this week"
                )
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Weekly goal")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(goalMessage)
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(engine.thisMonthCount) this month")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
                Spacer(minLength: 0)
            }
            .cardStyle()

            HStack(spacing: 12) {
                ForEach(engine.rateMetrics) { metric in
                    StatTile(value: metric.display, title: metric.title, subtitle: metric.subtitle,
                             symbol: iconFor(metric.id), tint: tintFor(metric.id))
                }
            }
        }
    }

    private var goalMessage: String {
        let remaining = settings.weeklyGoal - engine.thisWeekCount
        if remaining <= 0 { return "Goal hit — nice momentum this week." }
        return "\(remaining) more to hit your goal this week."
    }

    // MARK: - Pro charts

    private var weeklyChart: some View {
        ChartCard(title: "Applications per week", symbol: "calendar") {
            let buckets = engine.weeklyBuckets(weeks: 10)
            Chart(buckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.label),
                    y: .value("Applications", bucket.count)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
                RuleMark(y: .value("Goal", settings.weeklyGoal))
                    .foregroundStyle(Theme.warn.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 180)
            .accessibilityLabel("Applications submitted per week over the last 10 weeks")
            .accessibilityValue(buckets.map { "\($0.label): \($0.count)" }.joined(separator: ", "))
        }
    }

    private var funnelChart: some View {
        ChartCard(title: "Conversion funnel", symbol: "line.3.horizontal.decrease") {
            let stages = engine.funnelStageCounts
            Chart(stages) { stage in
                BarMark(
                    x: .value("Count", stage.count),
                    y: .value("Stage", stage.status.label)
                )
                .foregroundStyle(stage.status.color.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(stage.count)")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .chartXAxis { AxisMarks(position: .bottom) }
            .frame(height: 200)
            .accessibilityLabel("Conversion funnel by stage")
            .accessibilityValue(stages.map { "\($0.status.label): \($0.count)" }.joined(separator: ", "))
        }
    }

    private var sourceChart: some View {
        ChartCard(title: "By source", symbol: "arrow.triangle.branch") {
            let sources = engine.bySource
            Chart(sources) { item in
                BarMark(
                    x: .value("Source", item.source.label),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(item.source.color.gradient)
                .cornerRadius(4)
            }
            .frame(height: 170)
            .accessibilityLabel("Applications by source")
            .accessibilityValue(sources.map { "\($0.source.label): \($0.count)" }.joined(separator: ", "))
        }
    }

    private var donutChart: some View {
        ChartCard(title: "Status distribution", symbol: "chart.pie") {
            let slices = engine.statusDistribution
            HStack(alignment: .center, spacing: 16) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Count", slice.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(slice.status.color)
                    .cornerRadius(3)
                }
                .frame(width: 140, height: 140)
                .accessibilityLabel("Status distribution donut")
                .accessibilityValue(slices.map { "\($0.status.label): \($0.count)" }.joined(separator: ", "))

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(slices) { slice in
                        HStack(spacing: 6) {
                            Circle().fill(slice.status.color).frame(width: 9, height: 9)
                            Text(slice.status.label)
                                .font(Theme.rounded(12))
                                .foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text("\(slice.count)")
                                .font(Theme.rounded(12, .semibold))
                                .foregroundStyle(Theme.ink)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var timeToResponseCard: some View {
        ChartCard(title: "Time to first response", symbol: "timer") {
            HStack {
                if let avg = engine.averageDaysToResponse {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(String(format: "%.1f", avg)) days")
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.ink)
                        Text("average from applying to first reply")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                } else {
                    Text("Not enough response data yet.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Upsell

    private var proUpsell: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Unlock the full dashboard")
                .font(Theme.rounded(19, .bold))
                .foregroundStyle(Theme.ink)
            Text("See your weekly cadence chart, conversion funnel, source breakdown, status donut and time-to-response — plus CSV export.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showingPaywall = true
            } label: {
                Text("Unlock \(ProStore.productName)")
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusL, style: .continuous).stroke(Theme.accent.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Helpers

    private func iconFor(_ id: String) -> String {
        switch id {
        case "response": return "envelope"
        case "interview": return "person.2"
        case "offer": return "checkmark.seal"
        default: return "chart.bar"
        }
    }
    private func tintFor(_ id: String) -> Color {
        switch id {
        case "response": return Theme.info
        case "interview": return AppStatus.interview.color
        case "offer": return Theme.warn
        default: return Theme.accent
        }
    }
}

/// Wrapper card for any chart with a consistent title bar.
struct ChartCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.ink)
            content
        }
        .cardStyle()
    }
}
