import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameRecord.date, order: .forward) private var records: [GameRecord]

    private var summary: StatsSummary {
        StatsEngine.summarize(records: records)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if summary.isEmpty {
                    EmptyStateView(
                        symbol: "chart.bar.xaxis",
                        title: "No games yet",
                        message: "Play a few rounds on the Play tab and your scores, streaks, and tile records will appear here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            overviewGrid
                            scoresCard
                            tilesCard
                            sizeBests
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: Overview

    private var overviewGrid: some View {
        let s = summary
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            StatChip(caption: "Games", value: "\(s.gamesPlayed)")
            StatChip(caption: "Win rate", value: "\(s.winRatePercent)%")
            StatChip(caption: "Best", value: AchievementEngine.formatted(s.bestScore))
            StatChip(caption: "Moves", value: AchievementEngine.formatted(s.totalMoves))
            StatChip(caption: "Time", value: s.totalTimeLabel)
            StatChip(caption: "Streak", value: "\(s.currentStreak)")
        }
    }

    // MARK: Scores over time

    private var scoresCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Scores over time", systemImage: "chart.line.uptrend.xyaxis")
            Chart(summary.scorePoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(Theme.accent)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(Theme.accentDeep)
                .symbolSize(18)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 180)
            .accessibilityLabel("Line chart of game scores over time. Best \(summary.bestScore).")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: Highest-tile distribution

    private var tilesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Highest tile reached", systemImage: "square.grid.2x2")
            Chart(summary.tileBuckets) { bucket in
                BarMark(
                    x: .value("Tile", "\(bucket.tile)"),
                    y: .value("Games", bucket.count)
                )
                .foregroundStyle(Theme.tileColors(forValue: bucket.tile).fill)
                .cornerRadius(5)
            }
            .frame(height: 180)
            .accessibilityLabel(tileChartAccessibility)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    private var tileChartAccessibility: String {
        let parts = summary.tileBuckets.map { "\($0.tile): \($0.count) games" }
        return "Bar chart of highest tile reached. " + parts.joined(separator: ", ") + "."
    }

    // MARK: Per-size bests

    private var sizeBests: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Best by board size", systemImage: "rectangle.grid.2x2")
            let sizes = summary.bestScoreBySize.keys.sorted()
            ForEach(sizes, id: \.self) { size in
                HStack {
                    Text("\(size) × \(size)")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(AchievementEngine.formatted(summary.bestScoreBySize[size] ?? 0))
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
            }
            HStack {
                Text("Best day streak")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(summary.bestStreak) days")
                    .font(Theme.rounded(16, .bold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.vertical, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }
}
