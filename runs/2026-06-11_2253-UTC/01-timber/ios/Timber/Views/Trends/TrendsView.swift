import SwiftUI
import SwiftData
import Charts

struct TrendsView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \NightSession.startedAt) private var sessions: [NightSession]

    private var recent: [NightSession] { Array(sessions.suffix(30)) }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.count < 2 {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "Trends arrive with data",
                                   message: "Monitor at least two nights and Timber will chart your scores, snoring time, and weekday patterns here.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryTiles
                            scoreChart
                            snoreTimeChart
                            weekdayChart
                        }
                        .padding()
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Trends")
        }
    }

    private var summaryTiles: some View {
        let scores = recent.map { SnoreEngine.score(for: $0) }
        let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
        let best = scores.min() ?? 0
        let avgSleep = recent.isEmpty ? 0 : recent.reduce(0.0) { $0 + $1.duration } / Double(recent.count)
        return HStack(spacing: 12) {
            StatTile(title: "Avg score", value: "\(avg)", caption: "last \(recent.count) nights")
            StatTile(title: "Best night", value: "\(best)")
            StatTile(title: "Avg in bed", value: SnoreEngine.formatDuration(avgSleep))
        }
    }

    private var scoreChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Snore Score").font(.headline)
            Chart(recent) { session in
                BarMark(x: .value("Night", session.startedAt, unit: .day),
                        y: .value("Score", SnoreEngine.score(for: session)))
                .foregroundStyle(Theme.scoreColor(SnoreEngine.score(for: session)))
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 170)
            .accessibilityLabel("Bar chart of Snore Score per night")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private var snoreTimeChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Time spent snoring").font(.headline)
            Chart(recent) { session in
                LineMark(x: .value("Night", session.startedAt, unit: .day),
                         y: .value("Minutes", session.episodes.reduce(0.0) { $0 + $1.duration } / 60))
                .foregroundStyle(Theme.amber)
                .interpolationMethod(.monotone)
                PointMark(x: .value("Night", session.startedAt, unit: .day),
                          y: .value("Minutes", session.episodes.reduce(0.0) { $0 + $1.duration } / 60))
                .foregroundStyle(Theme.amber)
            }
            .chartYAxisLabel("min")
            .frame(height: 150)
            .accessibilityLabel("Line chart of snoring minutes per night")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }

    private var weekdayChart: some View {
        let data = SnoreEngine.weekdayAverages(sessions: sessions)
        let symbols = Calendar.current.shortWeekdaySymbols
        return VStack(alignment: .leading, spacing: 10) {
            Text("By weekday").font(.headline)
            Text("Do weekends sound different?")
                .font(.caption)
                .foregroundStyle(Theme.inkSecondary(scheme))
            Chart(data, id: \.weekday) { item in
                BarMark(x: .value("Weekday", symbols[(item.weekday - 1 + 7) % 7]),
                        y: .value("Avg score", item.average))
                .foregroundStyle(Theme.moss)
                .cornerRadius(3)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 150)
            .accessibilityLabel("Average Snore Score by weekday")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .timberCard()
    }
}
