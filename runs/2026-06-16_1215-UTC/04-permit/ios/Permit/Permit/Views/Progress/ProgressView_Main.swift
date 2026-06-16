import SwiftUI
import SwiftData
import Charts

/// Renamed to avoid clashing with SwiftUI.ProgressView.
struct ProgressView_Main: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var pro: ProStore
    @EnvironmentObject private var settings: AppSettings
    @Query private var stats: [QuestionStat]
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]

    @State private var showPaywall = false
    @State private var reviewSession: ExamSession?

    private var trend: [ScorePoint] { ProgressEngine.mockTrend(results: results) }
    private var categoryProgress: [CategoryProgress] { ProgressEngine.categoryProgress(stats: stats) }
    private var passRate: Int { ProgressEngine.passRate(results: results) }
    private var mockCount: Int { ProgressEngine.mockCount(results: results) }
    private var readiness: Int { ProgressEngine.readiness(stats: stats) }

    private var hasActivity: Bool { !stats.isEmpty || !results.isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if !pro.isPro {
                    lockedView
                } else if !hasActivity {
                    EmptyStateView(
                        systemImage: "chart.bar.xaxis",
                        title: "No progress yet",
                        message: "Take a practice round or a mock exam and your analytics will appear here."
                    )
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Progress")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(item: $reviewSession) { s in
                PracticePlayerView(session: s)
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryRow
                trendCard
                categoryCard
                reviewCard
            }
            .padding(16)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryTile("Readiness", "\(readiness)%", "checkmark.seal.fill", Theme.accent)
            summaryTile("Pass rate", "\(passRate)%", "trophy.fill", Theme.good)
            summaryTile("Mocks", "\(mockCount)", "doc.text.fill", Theme.warn)
        }
    }

    private func summaryTile(_ label: String, _ value: String, _ symbol: String, _ color: Color) -> some View {
        Card(padding: 12) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 18)).foregroundStyle(color)
                    .accessibilityHidden(true)
                Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }

    private var trendCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mock score trend").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                if trend.isEmpty {
                    Text("Take a mock exam to start your trend line.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    Chart {
                        RuleMark(y: .value("Pass mark", 80))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .foregroundStyle(Theme.inkSoft.opacity(0.6))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Pass 80%").font(Theme.rounded(10)).foregroundStyle(Theme.inkSoft)
                            }
                        ForEach(trend) { p in
                            LineMark(x: .value("Date", p.date), y: .value("Score", p.percent))
                                .foregroundStyle(Theme.accent)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", p.date), y: .value("Score", p.percent))
                                .foregroundStyle(p.passed ? Theme.good : Theme.bad)
                        }
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 180)
                    .accessibilityLabel("Mock score trend")
                    .accessibilityValue("Latest score \(trend.last?.percent ?? 0) percent over \(trend.count) mocks")
                }
            }
        }
    }

    private var categoryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Accuracy by topic").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                Chart {
                    ForEach(categoryProgress) { cp in
                        BarMark(
                            x: .value("Accuracy", cp.accuracyPercent),
                            y: .value("Topic", shortName(cp.category))
                        )
                        .foregroundStyle(barColor(cp.accuracyPercent))
                        .annotation(position: .trailing) {
                            Text("\(cp.accuracyPercent)%")
                                .font(Theme.rounded(10, .semibold)).foregroundStyle(Theme.inkSoft)
                        }
                    }
                }
                .chartXScale(domain: 0...100)
                .frame(height: CGFloat(categoryProgress.count) * 34 + 20)
                .accessibilityLabel("Accuracy by topic chart")
            }
        }
    }

    private func shortName(_ c: QuestionCategory) -> String {
        switch c {
        case .roadSigns: return "Signs"
        case .signalsMarkings: return "Signals"
        case .rulesOfRoad: return "Rules"
        case .rightOfWay: return "Right-of-Way"
        case .speedSafety: return "Speed"
        case .parkingTurning: return "Parking"
        case .alcoholDrugs: return "Alcohol"
        case .sharingRoad: return "Sharing"
        }
    }

    private func barColor(_ pct: Int) -> Color {
        if pct >= 80 { return Theme.good }
        if pct >= 50 { return Theme.warn }
        return Theme.bad
    }

    private var reviewCard: some View {
        let ids = ProgressEngine.reviewableIDs(stats: stats)
        let count = Set(ids.missed).union(ids.flagged).count
        return Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Flagged & missed").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                if count == 0 {
                    Text("No flagged or missed questions right now. Nice and clean!")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                } else {
                    Text("You have \(count) question\(count == 1 ? "" : "s") to revisit.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                    PrimaryButton(title: "Review now", systemImage: "arrow.uturn.backward") {
                        Haptics.tap(settings.hapticsEnabled)
                        reviewSession = ExamEngine.buildReview(missedIDs: ids.missed, flaggedIDs: ids.flagged, limit: 20)
                    }
                }
            }
        }
    }

    private var lockedView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Mock score trend").font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                        Chart {
                            ForEach(sampleTrend) { p in
                                LineMark(x: .value("Date", p.date), y: .value("Score", p.percent))
                                    .foregroundStyle(Theme.accent.opacity(0.5))
                                    .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYScale(domain: 0...100)
                        .frame(height: 150)
                    }
                }
                .opacity(0.5)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40)).foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text("Progress analytics is a Pro feature")
                        .font(Theme.rounded(19, .bold)).foregroundStyle(Theme.ink)
                    Text("See your readiness over time, per-topic accuracy, pass rate and a review list with Permit Pro.")
                        .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                    PrimaryButton(title: "Unlock Permit Pro", systemImage: "crown.fill") {
                        showPaywall = true
                    }
                }
            }
            .padding(16)
        }
    }

    private var sampleTrend: [ScorePoint] {
        let cal = Calendar.current
        return (0..<5).reversed().map { i in
            ScorePoint(date: cal.date(byAdding: .day, value: -i * 2, to: .now) ?? .now,
                       percent: 55 + (5 - i) * 6, passed: i < 2)
        }
    }
}
