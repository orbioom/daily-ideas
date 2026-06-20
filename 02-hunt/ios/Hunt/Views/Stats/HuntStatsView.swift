import SwiftUI
import SwiftData
import Charts

struct HuntStatsView: View {
    @Query(sort: \HuntResult.date, order: .reverse) private var results: [HuntResult]

    private var last14Days: [DayScore] {
        let cal = Calendar.current
        let now = Date()
        return (0..<14).reversed().compactMap { offset -> DayScore? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: now) else { return nil }
            let start = cal.startOfDay(for: day)
            let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
            let dayResults = results.filter { $0.date >= start && $0.date < end && !$0.isDaily }
            let totalScore = dayResults.reduce(0) { $0 + $1.score }
            return DayScore(date: day, score: totalScore)
        }
    }

    private var totalGames: Int { results.filter { !$0.isDaily }.count }
    private var bestScore: Int { results.filter { !$0.isDaily }.map(\.score).max() ?? 0 }
    private var avgWords: Double {
        let nonDaily = results.filter { !$0.isDaily }
        guard !nonDaily.isEmpty else { return 0 }
        return Double(nonDaily.reduce(0) { $0 + $1.wordsFound }) / Double(nonDaily.count)
    }
    private var bestGame: HuntResult? { results.filter { !$0.isDaily }.max(by: { $0.score < $1.score }) }

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Stats")
                        .font(.largeTitle.bold())
                        .foregroundStyle(HuntTheme.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    if results.isEmpty {
                        emptyState
                    } else {
                        // Summary cards
                        HStack(spacing: 12) {
                            StatCard(title: "Games", value: "\(totalGames)", icon: "gamecontroller.fill")
                            StatCard(title: "Best Score", value: "\(bestScore)", icon: "star.fill")
                            StatCard(title: "Avg Words", value: String(format: "%.1f", avgWords), icon: "text.word.spacing")
                        }
                        .padding(.horizontal, 20)

                        // Chart
                        chartSection

                        // Best game
                        if let best = bestGame {
                            bestGameSection(best)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 56))
                .foregroundStyle(HuntTheme.secondaryText)

            Text("No games yet")
                .font(.title3.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Text("Play a few games to see your stats here.")
                .font(.body)
                .foregroundStyle(HuntTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 14 Days")
                .font(.headline)
                .foregroundStyle(HuntTheme.primaryText)

            Chart(last14Days) { day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Score", day.score)
                )
                .foregroundStyle(HuntTheme.accent.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { value in
                    AxisValueLabel(format: .dateTime.day())
                        .foregroundStyle(HuntTheme.secondaryText)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(HuntTheme.secondaryText)
                    AxisGridLine()
                        .foregroundStyle(HuntTheme.tileBackground.opacity(0.5))
                }
            }
            .frame(height: 160)
            .chartPlotStyle { plot in
                plot.background(HuntTheme.cardBackground)
            }
        }
        .padding(16)
        .background(HuntTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func bestGameSection(_ game: HuntResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Game")
                .font(.headline)
                .foregroundStyle(HuntTheme.primaryText)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(HuntTheme.secondaryText)
                    Text("\(game.score) pts")
                        .font(.title2.bold())
                        .foregroundStyle(HuntTheme.primaryText)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(game.wordsFound)/\(game.totalWords) words")
                        .font(.callout)
                        .foregroundStyle(HuntTheme.secondaryText)
                    Text(String(format: "%.0f%% coverage", Double(game.wordsFound) / max(1, Double(game.totalWords)) * 100))
                        .font(.caption)
                        .foregroundStyle(HuntTheme.accent)
                }
            }
        }
        .padding(16)
        .background(HuntTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(HuntTheme.accent)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(HuntTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(HuntTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(HuntTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DayScore: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
}

#Preview {
    HuntStatsView()
        .modelContainer(for: HuntResult.self, inMemory: true)
}
