import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Article.dateAdded, order: .reverse) private var articles: [Article]
    @Query(sort: \ReadingSession.date, order: .reverse) private var sessions: [ReadingSession]

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Reading Yet",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Complete your first reading session to see stats here.")
                )
                .listRowBackground(Color.clear)
            } else {
                overviewSection
                speedHistoryChart
                articleStatsSection
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    private var overviewSection: some View {
        Section("Overview") {
            let totalWords = sessions.map(\.wordIndex).reduce(0, +)
            let totalMinutes = Int(sessions.map(\.durationSeconds).reduce(0, +) / 60)
            let avgSpeed = sessions.isEmpty ? 0 : sessions.map(\.speedWPM).reduce(0, +) / sessions.count
            let completed = articles.filter(\.isCompleted).count

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statTile("Words Read", value: formatNumber(totalWords))
                statTile("Minutes Read", value: "\(totalMinutes)")
                statTile("Avg Speed", value: "\(avgSpeed) WPM")
                statTile("Articles Done", value: "\(completed)")
            }
        }
    }

    private func statTile(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(SkimTheme.accent)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }

    @ViewBuilder
    private var speedHistoryChart: some View {
        let slice = sessions.prefix(30).reversed().map { $0 }
        if slice.count >= 2 {
            Section("Speed History (last 30 sessions)") {
                Chart(slice.indices, id: \.self) { i in
                    LineMark(
                        x: .value("Session", i),
                        y: .value("WPM", slice[i].speedWPM)
                    )
                    .foregroundStyle(SkimTheme.accent.gradient)
                    PointMark(
                        x: .value("Session", i),
                        y: .value("WPM", slice[i].speedWPM)
                    )
                    .foregroundStyle(SkimTheme.accent)
                }
                .chartYAxisLabel("WPM")
                .frame(height: 150)
                .accessibilityLabel("Line chart of reading speed over last 30 sessions")
            }
        }
    }

    private var articleStatsSection: some View {
        let nonEmpty = articles.filter { !$0.sessions.isEmpty }
        return Section("Articles (\(nonEmpty.count))") {
            ForEach(nonEmpty) { article in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(article.title)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(1)
                        Text("\(article.totalReadingMinutes) min read · \(Int(article.progressFraction * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if article.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(article.title). \(article.totalReadingMinutes) minutes read. \(Int(article.progressFraction * 100))% complete.")
            }
        }
    }

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 { return "\(n / 1000)k" }
        return "\(n)"
    }
}
