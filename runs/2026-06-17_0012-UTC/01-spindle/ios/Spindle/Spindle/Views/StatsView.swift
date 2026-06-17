import SwiftUI
import SwiftData
import Charts

/// Aggregate stats over all recorded games, with two Swift Charts.
struct StatsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(PrefKey.isPro) private var isPro: Bool = false
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                SpindleBackground()
                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            summaryGrid
                            winRateChart
                            last30Chart
                            streakCard
                            if !isPro { proHistoryNote }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Stats")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: Derived stats

    /// Free users see a limited history window; Pro sees everything.
    private var visibleResults: [GameResult] {
        isPro ? results : Array(results.prefix(20))
    }

    private var played: Int { visibleResults.count }
    private var wins: Int { visibleResults.filter(\.won).count }
    private var winRate: Double { played == 0 ? 0 : Double(wins) / Double(played) }

    private var bestTime: Int? {
        visibleResults.filter(\.won).map(\.durationSeconds).min()
    }
    private var fewestMoves: Int? {
        visibleResults.filter(\.won).map(\.moves).min()
    }
    private var averageScore: Int {
        guard !visibleResults.isEmpty else { return 0 }
        let total = visibleResults.reduce(0) { $0 + $1.score }
        return total / visibleResults.count
    }

    private func winRate(for mode: SuitMode) -> Double {
        let subset = visibleResults.filter { $0.suitCount == mode.rawValue }
        guard !subset.isEmpty else { return 0 }
        return Double(subset.filter(\.won).count) / Double(subset.count)
    }

    private func played(for mode: SuitMode) -> Int {
        visibleResults.filter { $0.suitCount == mode.rawValue }.count
    }

    /// Current and best win streak (chronological).
    private var streaks: (current: Int, best: Int) {
        let chrono = visibleResults.sorted { $0.date < $1.date }
        var best = 0, run = 0, current = 0
        for r in chrono {
            if r.won { run += 1; best = max(best, run) } else { run = 0 }
        }
        // Current streak counts trailing wins.
        for r in chrono.reversed() {
            if r.won { current += 1 } else { break }
        }
        return (current, best)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(SpindleTheme.emerald)
                .accessibilityHidden(true)
            Text("No games yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(SpindleTheme.primaryText(scheme))
            Text("Finish a game and your wins, times and streaks will appear here.")
                .font(.subheadline)
                .foregroundStyle(SpindleTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: Summary

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            statTile("Games", "\(played)", "rectangle.stack")
            statTile("Wins", "\(wins)", "trophy.fill")
            statTile("Win rate", "\(Int((winRate * 100).rounded()))%", "percent")
            statTile("Avg score", "\(averageScore)", "number")
            statTile("Best time", bestTime.map(formatTime) ?? "—", "stopwatch")
            statTile("Fewest moves", fewestMoves.map { "\($0)" } ?? "—", "figure.walk.motion")
        }
    }

    private func statTile(_ title: String, _ value: String, _ icon: String) -> some View {
        SpindleCard(padding: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(SpindleTheme.emerald)
                    .accessibilityHidden(true)
                Text(value)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(SpindleTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    // MARK: Win-rate chart

    private struct DifficultyRate: Identifiable {
        let id = UUID()
        let label: String
        let rate: Double
        let games: Int
    }

    private var difficultyRates: [DifficultyRate] {
        SuitMode.allCases.map {
            DifficultyRate(label: $0.title, rate: winRate(for: $0), games: played(for: $0))
        }
    }

    private var winRateChart: some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Win rate by difficulty")
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                Chart(difficultyRates) { item in
                    BarMark(
                        x: .value("Difficulty", item.label),
                        y: .value("Win rate", item.rate)
                    )
                    .foregroundStyle(SpindleTheme.emerald)
                    .cornerRadius(5)
                    .annotation(position: .top) {
                        Text("\(Int((item.rate * 100).rounded()))%")
                            .font(.caption2)
                            .foregroundStyle(SpindleTheme.secondaryText(scheme))
                    }
                }
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(values: [0, 0.5, 1]) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let d = value.as(Double.self) {
                                Text("\(Int(d * 100))%")
                            }
                        }
                    }
                }
                .frame(height: 180)
                .accessibilityLabel("Win rate by difficulty chart")
                .accessibilityValue(difficultyRates.map { "\($0.label): \(Int(($0.rate * 100).rounded())) percent over \($0.games) games" }.joined(separator: ", "))
            }
        }
    }

    // MARK: Last-30-days chart

    private struct DayCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private var last30: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var buckets: [Date: Int] = [:]
        for r in visibleResults {
            let day = cal.startOfDay(for: r.date)
            buckets[day, default: 0] += 1
        }
        return (0..<30).reversed().compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayCount(date: day, count: buckets[day] ?? 0)
        }
    }

    private var last30Chart: some View {
        SpindleCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Games played · last 30 days")
                    .font(.headline)
                    .foregroundStyle(SpindleTheme.primaryText(scheme))
                Chart(last30) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Games", day.count)
                    )
                    .foregroundStyle(SpindleTheme.goldDeep)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 160)
                .accessibilityLabel("Games played over the last 30 days")
                .accessibilityValue("\(visibleResults.count) games in the visible window")
            }
        }
    }

    // MARK: Streak

    private var streakCard: some View {
        SpindleCard {
            HStack {
                streakStat("Current streak", streaks.current)
                Divider().frame(height: 40)
                streakStat("Best streak", streaks.best)
            }
        }
    }

    private func streakStat(_ title: String, _ value: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title.weight(.bold))
                .foregroundStyle(SpindleTheme.emeraldDeep)
            Text(title)
                .font(.caption)
                .foregroundStyle(SpindleTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }

    private var proHistoryNote: some View {
        Button { showPaywall = true } label: {
            SpindleCard {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill").foregroundStyle(SpindleTheme.goldDeep)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Full stats history")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SpindleTheme.primaryText(scheme))
                        Text("Free shows your latest 20 games. Unlock Pro for your complete history.")
                            .font(.caption)
                            .foregroundStyle(SpindleTheme.secondaryText(scheme))
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Helpers

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
