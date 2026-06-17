import SwiftUI
import SwiftData
import Charts

/// Charts and history: readiness over time, per-topic mastery, pass rate, and mock log.
struct ProgressDashboardView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \ExamResult.date, order: .reverse) private var results: [ExamResult]
    @Query private var stats: [QuestionStat]

    private var hasResults: Bool { !results.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                if !hasResults {
                    EmptyStateCard(systemImage: "chart.line.uptrend.xyaxis",
                                   title: "No results yet",
                                   message: "Finish a quiz or mock exam and your scores, mastery, and trends will appear here.")
                        .padding(.top, 40)
                        .padding(16)
                } else {
                    VStack(spacing: 18) {
                        summaryTiles
                        scoreTrendCard
                        topicMasteryCard
                        historyCard
                    }
                    .padding(16)
                }
            }
            .background(Theme.background(scheme).ignoresSafeArea())
            .navigationTitle("Progress")
        }
    }

    private var summaryTiles: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(Int((ProgressEngine.readiness(stats: stats, totalQuestions: QuestionBank.all.count) * 100).rounded()))%",
                     caption: "readiness", systemImage: "gauge.medium", tint: Theme.accent)
            StatTile(value: "\(Int((ProgressEngine.passRate(results: results) * 100).rounded()))%",
                     caption: "mock pass rate", systemImage: "checkmark.seal", tint: Theme.success(scheme))
            StatTile(value: "\(ProgressEngine.studyStreak(results: results))",
                     caption: "day streak", systemImage: "flame.fill", tint: Theme.gold)
        }
    }

    // MARK: Score trend

    private var scoreTrendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Score trend", subtitle: "Your last sessions, oldest to newest")
            let points = scorePoints
            Chart(points) { p in
                LineMark(x: .value("Session", p.index), y: .value("Score", p.percent))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.accent)
                PointMark(x: .value("Session", p.index), y: .value("Score", p.percent))
                    .foregroundStyle(p.passed ? Theme.success(scheme) : Theme.accent)
                RuleMark(y: .value("Pass", 75))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Theme.textSecondary(scheme).opacity(0.6))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis { AxisMarks(values: [0, 25, 50, 75, 100]) }
            .chartXAxis(.hidden)
            .frame(height: 180)
            .accessibilityLabel("Score trend chart over \(points.count) sessions")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private struct ScorePoint: Identifiable {
        let id = UUID()
        let index: Int
        let percent: Int
        let passed: Bool
    }

    private var scorePoints: [ScorePoint] {
        // Oldest to newest, limited to the most recent 20 for readability.
        let recent = Array(results.prefix(20)).reversed()
        return recent.enumerated().map { idx, r in
            ScorePoint(index: idx + 1, percent: r.percent, passed: r.passed)
        }
    }

    // MARK: Topic mastery

    private var topicMasteryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "Mastery by topic")
            Chart(Topic.allCases) { topic in
                BarMark(
                    x: .value("Mastery", ProgressEngine.topicMastery(topic, stats: stats) * 100),
                    y: .value("Topic", topic.shortTitle)
                )
                .foregroundStyle(topic.chipColor)
                .annotation(position: .trailing) {
                    Text("\(Int((ProgressEngine.topicMastery(topic, stats: stats) * 100).rounded()))")
                        .font(.caption2)
                        .foregroundStyle(Theme.textSecondary(scheme))
                }
            }
            .chartXScale(domain: 0...100)
            .frame(height: 320)
            .accessibilityLabel("Mastery by topic bar chart")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: History

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(text: "History")
            ForEach(results.prefix(25)) { r in
                HStack(spacing: 12) {
                    Image(systemName: r.passed ? "checkmark.seal.fill" : "circle.dashed")
                        .foregroundStyle(r.passed ? Theme.success(scheme) : Theme.textSecondary(scheme))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.modeLabel + (r.topic.map { " · \($0.shortTitle)" } ?? ""))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.textPrimary(scheme))
                        Text(r.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(Theme.textSecondary(scheme))
                    }
                    Spacer()
                    Text("\(r.percent)%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(r.percent >= 75 ? Theme.success(scheme) : Theme.accent)
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(r.modeLabel), \(r.percent) percent, \(r.date.formatted(date: .abbreviated, time: .omitted))")
                if r.id != results.prefix(25).last?.id { Divider() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
