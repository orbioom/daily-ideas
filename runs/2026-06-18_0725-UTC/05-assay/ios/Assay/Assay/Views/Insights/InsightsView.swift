import SwiftUI
import SwiftData
import Charts

/// Analytics: status breakdown by category, in-range over time, and the
/// markers most out of range. Uses Swift Charts throughout.
struct InsightsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Query private var results: [LabResult]

    @State private var showPaywall = false

    private var sex: BiologicalSex { settings.biologicalSex }
    private var snapshots: [MarkerSnapshot] { LabAnalytics.latestSnapshots(from: results, sex: sex) }
    private var rollups: [CategoryRollup] { StatsEngine.categoryRollups(from: snapshots) }
    private var overTime: [(date: Date, fraction: Double)] { LabAnalytics.inRangeOverTime(from: results, sex: sex) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if results.isEmpty {
                    EmptyStateView(
                        icon: "chart.xyaxis.line",
                        title: "Nothing to chart yet",
                        message: "Log a panel and your insights will populate here — category breakdowns, trends and more."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if pro.isPro {
                                categoryChart
                                trendChart
                                worstMarkers
                            } else {
                                categoryChart
                                proGate
                            }
                            exportAll
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Insights")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Category breakdown (stacked bars)

    private struct CatBar: Identifiable {
        let category: String
        let status: String
        let count: Int
        let color: Color
        var id: String { category + status }
    }

    private var catBars: [CatBar] {
        var out: [CatBar] = []
        for r in rollups {
            out.append(CatBar(category: r.category.rawValue, status: "Optimal", count: r.optimal, color: Theme.good))
            out.append(CatBar(category: r.category.rawValue, status: "In range", count: r.inRange, color: Theme.okay))
            out.append(CatBar(category: r.category.rawValue, status: "Out of range", count: r.outOfRange, color: Theme.bad))
        }
        return out
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("Status by category", "checklist")
            if catBars.allSatisfy({ $0.count == 0 }) {
                Text("No classified markers yet.")
                    .font(.subheadline).foregroundStyle(Theme.inkSoft)
            } else {
                Chart(catBars) { bar in
                    BarMark(
                        x: .value("Count", bar.count),
                        y: .value("Category", bar.category)
                    )
                    .foregroundStyle(bar.color)
                }
                .chartForegroundStyleScale([
                    "Optimal": Theme.good, "In range": Theme.okay, "Out of range": Theme.bad
                ])
                .chartLegend(position: .bottom)
                .frame(height: max(180, CGFloat(rollups.count) * 30))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) {
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel()
                    }
                }
                .accessibilityLabel("Marker status grouped by category")
            }
        }
        .assayCard()
    }

    // MARK: - In-range over time (line)

    private struct TimePoint: Identifiable {
        let date: Date
        let percent: Double
        var id: Date { date }
    }

    private var timePoints: [TimePoint] {
        overTime.map { TimePoint(date: $0.date, percent: $0.fraction * 100) }
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("In-range over time", "chart.line.uptrend.xyaxis")
            if timePoints.count < 2 {
                Text("Log at least two panels to see your in-range trend.")
                    .font(.subheadline).foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                Chart(timePoints) { p in
                    AreaMark(x: .value("Date", p.date), y: .value("In range %", p.percent))
                        .foregroundStyle(Theme.accent.opacity(0.15))
                    LineMark(x: .value("Date", p.date), y: .value("In range %", p.percent))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Theme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    PointMark(x: .value("Date", p.date), y: .value("In range %", p.percent))
                        .foregroundStyle(Theme.accent)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisGridLine().foregroundStyle(Theme.hairline)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits))
                    }
                }
                .accessibilityLabel("Percentage of markers in range across panels over time")
            }
        }
        .assayCard()
    }

    // MARK: - Worst markers (bar)

    private struct OutBar: Identifiable {
        let name: String
        let severity: Int
        let status: MarkerStatus
        var id: String { name }
    }

    private var worstBars: [OutBar] {
        snapshots
            .filter { $0.assessment.status.isOutOfRange }
            .sorted { $0.assessment.severity > $1.assessment.severity }
            .prefix(6)
            .map { OutBar(name: $0.marker.shortName, severity: $0.assessment.severity.rawValue, status: $0.assessment.status) }
    }

    private var worstMarkers: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader("Most out of range", "exclamationmark.triangle")
            if worstBars.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                    Text("No markers are out of range right now.")
                        .font(.subheadline).foregroundStyle(Theme.inkSoft)
                }
            } else {
                Chart(worstBars) { bar in
                    BarMark(
                        x: .value("Severity", bar.severity),
                        y: .value("Marker", bar.name)
                    )
                    .foregroundStyle(bar.status.color)
                    .annotation(position: .trailing) {
                        Text(bar.status.rawValue)
                            .font(.caption2)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXScale(domain: 0...3.6)
                .chartXAxis(.hidden)
                .frame(height: max(140, CGFloat(worstBars.count) * 34))
                .accessibilityLabel("Markers ranked by how far out of range they are")
            }
        }
        .assayCard()
    }

    // MARK: - Pro gate

    private var proGate: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Unlock trend insights", systemImage: "lock.fill")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(Theme.ink)
            Text("Assay Pro adds your in-range trend over time and a ranking of the markers most out of range — plus full-history export.")
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                showPaywall = true
            } label: {
                Text("See Pro")
                    .font(Theme.rounded(15, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .assayCard()
    }

    // MARK: - Export all (Pro)

    @ViewBuilder
    private var exportAll: some View {
        if pro.isPro {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader("Export everything", "square.and.arrow.up")
                Text("Share your full history as a CSV for your records or your doctor.")
                    .font(.subheadline).foregroundStyle(Theme.inkSoft)
                ShareLink(item: ReportExporter.csvAll(results: results, sex: sex),
                          preview: SharePreview("Assay full history CSV")) {
                    HStack {
                        Image(systemName: "tablecells")
                        Text("Export full history (CSV)").font(Theme.rounded(15, .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accentSoft)
                    .foregroundStyle(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .assayCard()
        }
    }

    private func cardHeader(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(title).font(Theme.rounded(16, .bold)).foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}
