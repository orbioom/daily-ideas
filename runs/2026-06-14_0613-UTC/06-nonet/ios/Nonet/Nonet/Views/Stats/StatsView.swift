import SwiftUI
import SwiftData
import Charts

/// Stats: games & win-rate by difficulty, best & average times, streak, solved-days
/// heatmap, total solved. Computes asynchronously with a loading state.
struct StatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @AppStorage(Pro.storageKey) private var isPro = false

    @State private var summary: StatsSummary? = nil
    @State private var computing = false
    @State private var paywall: PaywallReason? = nil

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(icon: "chart.bar",
                                   title: "No Stats Yet",
                                   message: "Finish a puzzle and your performance will show up here.")
                } else if computing || summary == nil {
                    loading
                } else if let s = summary {
                    content(s)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .sheet(item: $paywall) { PaywallView(reason: $0) }
        }
        .task(id: records.count) { await recompute() }
    }

    private var loading: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Crunching your stats…")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Computing stats")
    }

    private func content(_ s: StatsSummary) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                headline(s)
                gamesByDifficultyCard(s)
                winRateCard(s)
                timesCard(s)
                heatmapCard(s)
                if !isPro {
                    proHint
                }
            }
            .padding(16)
        }
    }

    // MARK: Headline tiles

    private func headline(_ s: StatsSummary) -> some View {
        HStack(spacing: 12) {
            tile("Solved", "\(s.totalWon)", "checkmark.seal.fill", Theme.success)
            tile("Streak", "\(s.currentStreak)", "flame.fill", Theme.warning)
            tile("Best Streak", "\(s.longestStreak)", "crown.fill", Theme.accent)
        }
    }

    private func tile(_ label: String, _ value: String, _ icon: String, _ tint: Color) -> some View {
        CardView(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.textPrimary)
                Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    // MARK: Games by difficulty

    private func gamesByDifficultyCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Games by Difficulty")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Chart(s.byDifficulty) { row in
                    BarMark(
                        x: .value("Difficulty", row.difficulty.title),
                        y: .value("Games", row.played)
                    )
                    .foregroundStyle(row.difficulty.tint)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis { AxisMarks(position: .leading) }
                .accessibilityLabel("Games played per difficulty")
            }
        }
    }

    // MARK: Win rate

    private func winRateCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Win Rate by Difficulty")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Chart(s.byDifficulty) { row in
                    BarMark(
                        x: .value("Win Rate", row.winRate),
                        y: .value("Difficulty", row.difficulty.title)
                    )
                    .foregroundStyle(row.difficulty.tint)
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(Int(row.winRate * 100))%")
                            .font(Theme.mono(11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartXScale(domain: 0.0...1.0)
                .frame(height: 180)
                .accessibilityLabel("Win rate per difficulty")
            }
        }
    }

    // MARK: Times

    private func timesCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Best & Average Times")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.textPrimary)
                ForEach(s.byDifficulty) { row in
                    HStack {
                        Image(systemName: row.difficulty.symbol)
                            .foregroundStyle(row.difficulty.tint)
                            .frame(width: 22)
                        Text(row.difficulty.title)
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(row.bestTime.map(Self.fmt) ?? "—")
                                .font(Theme.mono(14, .semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text("avg \(row.avgTime.map(Self.fmt) ?? "—")")
                                .font(Theme.mono(11))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(row.difficulty.title) best \(row.bestTime.map(Self.fmt) ?? "none")")
                    if row.difficulty != s.byDifficulty.last?.difficulty {
                        Divider().background(Theme.separator)
                    }
                }
            }
        }
    }

    // MARK: Heatmap of solved days

    private func heatmapCard(_ s: StatsSummary) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Solved Days — Last 5 Weeks")
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.textPrimary)
                let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
                LazyVGrid(columns: cols, spacing: 5) {
                    ForEach(s.heatmap) { day in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(day.solved ? Theme.accent.opacity(day.intensity) : Theme.separator.opacity(0.5))
                            .aspectRatio(1, contentMode: .fit)
                            .accessibilityLabel(day.solved ? "\(day.label): \(day.count) solved" : "\(day.label): none")
                    }
                }
                HStack(spacing: 6) {
                    Text("Less").font(Theme.rounded(11)).foregroundStyle(Theme.textSecondary)
                    ForEach([0.3, 0.55, 0.8, 1.0], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Theme.accent.opacity(v))
                            .frame(width: 14, height: 14)
                    }
                    Text("More").font(Theme.rounded(11)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var proHint: some View {
        Button { paywall = .stats } label: {
            HStack {
                Image(systemName: "lock.fill").foregroundStyle(Theme.accent)
                Text("Nonet Pro keeps your full history and deeper stats.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .background(Theme.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        }
    }

    // MARK: Compute

    private func recompute() async {
        computing = true
        let snapshot = records.map {
            RecordLite(difficultyRaw: $0.difficultyRaw, timeSec: $0.timeSec,
                       won: $0.won, dateKey: $0.dateKey, date: $0.date)
        }
        let current = StreakStore.displayCurrent()
        let longest = StreakStore.longest
        let result = await Task.detached(priority: .userInitiated) {
            StatsSummary.build(from: snapshot, currentStreak: current, longestStreak: longest)
        }.value
        summary = result
        computing = false
    }

    static func fmt(_ sec: Int) -> String {
        let m = sec / 60, s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
}
