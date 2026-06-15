import SwiftUI
import SwiftData
import Charts

/// Player stats: totals, per-layout breakdown, daily streaks, and two charts
/// (games over last 14 days, win-rate by layout). Calm empty state.
struct StatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Query private var dailies: [DailyResult]

    private var snapshots: [StatsEngine.RecordSnapshot] {
        records.map { .init(layout: $0.layout, won: $0.won, durationSec: $0.durationSec, moves: $0.moves, date: $0.date) }
    }
    private var dailySnaps: [StatsEngine.DailySnapshot] {
        dailies.map { .init(dateKey: $0.dateKey, won: $0.won) }
    }
    private var perLayout: [StatsEngine.LayoutStats] {
        StatsEngine.perLayout(snapshots)
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Stats")
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 46)).foregroundStyle(Theme.inkFaint)
            Text("No games yet")
                .font(Theme.serif(22, .semibold)).foregroundStyle(Theme.ink)
            Text("Play a board and your times, win rate, and streaks will appear here.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                totals
                gamesChart
                winRateChart
                perLayoutSection
            }
            .padding(20)
        }
    }

    private var totals: some View {
        let played = StatsEngine.totalPlayed(snapshots)
        let wins = StatsEngine.totalWins(snapshots)
        let rate = StatsEngine.overallWinRate(snapshots)
        let streak = StatsEngine.streaks(dailySnaps)
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            totalTile("Games played", "\(played)", "square.stack.3d.up.fill")
            totalTile("Boards won", "\(wins)", "checkmark.seal.fill")
            totalTile("Win rate", played == 0 ? "—" : "\(Int((rate*100).rounded()))%", "percent")
            totalTile("Daily streak", "\(streak.current)", "flame.fill")
        }
    }

    private func totalTile(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(Theme.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .cardSurface(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Charts

    private var gamesChart: some View {
        let points = StatsEngine.gamesPerDay(snapshots, days: 14)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Games · last 14 days")
                .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
            Chart(points) { p in
                BarMark(
                    x: .value("Day", p.date, unit: .day),
                    y: .value("Games", p.games)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 3)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 160)
            .accessibilityLabel("Bar chart of games played per day over the last 14 days")
        }
        .cardSurface()
    }

    private var winRateChart: some View {
        let played = perLayout.filter { $0.played > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            Text("Win rate by layout")
                .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
            if played.isEmpty {
                Text("Win a few boards to see this.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkFaint)
                    .padding(.vertical, 20)
            } else {
                Chart(played) { stat in
                    BarMark(
                        x: .value("Win rate", stat.winRate),
                        y: .value("Layout", stat.layout.displayName)
                    )
                    .foregroundStyle(Theme.gold.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(Int((stat.winRate*100).rounded()))%")
                            .font(Theme.rounded(11)).foregroundStyle(Theme.inkSoft)
                    }
                }
                .chartXScale(domain: 0...1)
                .chartXAxis {
                    AxisMarks(format: .percent, values: [0, 0.5, 1])
                }
                .frame(height: CGFloat(played.count) * 44 + 20)
                .accessibilityLabel("Bar chart of win rate by layout")
            }
        }
        .cardSurface()
    }

    // MARK: Per layout

    private var perLayoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By layout")
                .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.ink)
            ForEach(perLayout) { stat in
                layoutRow(stat)
            }
        }
    }

    private func layoutRow(_ stat: StatsEngine.LayoutStats) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stat.layout.displayName)
                    .font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(stat.played) played")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
            }
            HStack(spacing: 18) {
                metric("Wins", "\(stat.wins)")
                metric("Win rate", stat.played == 0 ? "—" : "\(Int((stat.winRate*100).rounded()))%")
                metric("Best", stat.bestTimeSec.map { TimeFormat.clock($0) } ?? "—")
                metric("Avg", stat.avgTimeSec.map { TimeFormat.clock($0) } ?? "—")
            }
        }
        .cardSurface(padding: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stat.layout.displayName): \(stat.played) played, \(stat.wins) wins")
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.accent).monospacedDigit()
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
        }
    }
}
