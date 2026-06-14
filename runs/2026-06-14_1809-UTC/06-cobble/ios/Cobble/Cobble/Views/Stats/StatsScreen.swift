import SwiftUI
import SwiftData
import Charts

/// Stats: best/average/total tiles, score distribution, score-over-time, lines-per-game,
/// and recent results. Empty state before any games; loading state while computing.
struct StatsScreen: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    @State private var summary: StatsSummary?
    @State private var computing = false

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    EmptyStateView(symbol: "chart.bar",
                                   title: "No games yet",
                                   message: "Finish a game and your scores, lines, and combos will show up here.")
                } else if computing || summary == nil {
                    loading
                } else if let s = summary {
                    content(s)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
        }
        .task(id: results.count) { await recompute() }
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Crunching your stats…")
                .font(Theme.rounded(15)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Computing stats")
    }

    private func content(_ s: StatsSummary) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                tiles(s)
                distributionCard(s)
                overTimeCard(s)
                linesCard(s)
                recentCard
            }
            .padding(16)
        }
    }

    // MARK: Tiles

    private func tiles(_ s: StatsSummary) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                tile("Best", "\(s.bestScore)", "crown.fill", Theme.accent)
                tile("Average", "\(s.averageScore)", "chart.line.uptrend.xyaxis", Theme.good)
                tile("Games", "\(s.totalGames)", "gamecontroller.fill", Theme.inkSoft)
            }
            HStack(spacing: 12) {
                tile("Lines", "\(s.totalLines)", "rectangle.split.3x1.fill", Theme.accent)
                tile("Top combo", "\(s.longestCombo)", "flame.fill", Theme.good)
                tile("Pieces", "\(s.totalPieces)", "square.grid.2x2.fill", Theme.inkSoft)
            }
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    // MARK: Charts

    private func distributionCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Score Distribution")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Chart(s.distribution) { bucket in
                    BarMark(
                        x: .value("Score", bucket.label),
                        y: .value("Games", bucket.count)
                    )
                    .foregroundStyle(Theme.accent.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Histogram of scores")
            }
        }
    }

    private func overTimeCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Score Over Time")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Chart(s.overTime) { point in
                    LineMark(
                        x: .value("Game", point.index),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Theme.good)
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Game", point.index),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(Theme.good.opacity(0.15))
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 180)
                .chartXAxis(.hidden)
                .accessibilityLabel("Score trend across games")
            }
        }
    }

    private func linesCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Lines Cleared — Recent Games")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                Chart(s.linesPerGame) { point in
                    BarMark(
                        x: .value("Game", point.index),
                        y: .value("Lines", point.lines)
                    )
                    .foregroundStyle(Theme.accent.opacity(0.85))
                    .cornerRadius(3)
                }
                .frame(height: 160)
                .chartXAxis(.hidden)
                .accessibilityLabel("Lines cleared per recent game")
            }
        }
    }

    // MARK: Recent results

    private var recentCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Games")
                    .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                ForEach(Array(results.prefix(8))) { r in
                    HStack(spacing: 12) {
                        Image(systemName: r.mode.symbol)
                            .font(.system(size: 14))
                            .foregroundStyle(r.mode.tint)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(r.score)")
                                .font(Theme.mono(16, .semibold)).foregroundStyle(Theme.ink)
                            Text(r.date.formatted(date: .abbreviated, time: .shortened))
                                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("\(r.linesCleared) lines")
                                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                            Text(r.mode.title)
                                .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(r.mode.title), score \(r.score), \(r.linesCleared) lines")
                    if r.id != results.prefix(8).last?.id {
                        Divider().overlay(Theme.hairline)
                    }
                }
            }
        }
    }

    // MARK: Compute

    private func recompute() async {
        guard !results.isEmpty else { summary = nil; return }
        computing = true
        let snapshot = results.map {
            ResultLite(date: $0.date, score: $0.score, linesCleared: $0.linesCleared,
                       piecesPlaced: $0.piecesPlaced, longestCombo: $0.longestCombo,
                       modeRaw: $0.modeRaw)
        }
        let result = await Task.detached(priority: .userInitiated) {
            StatsSummary.build(from: snapshot)
        }.value
        summary = result
        computing = false
    }
}
