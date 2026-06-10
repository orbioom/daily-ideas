import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var allStats: [GameStats]
    @Query private var games: [SavedGame]

    private var ordered: [GameStats] {
        Difficulty.allCases.compactMap { d in allStats.first { $0.difficultyRaw == d.rawValue } }
    }
    private var totalWon: Int { allStats.reduce(0) { $0 + $1.won } }
    private var totalPlayed: Int { allStats.reduce(0) { $0 + $1.played } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if totalPlayed == 0 {
                    EmptyStateView(icon: "chart.bar", title: "No games yet",
                                   message: "Play and finish a puzzle to start building your stats.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            overallCard
                            chartCard
                            ForEach(ordered) { stat in difficultyCard(stat) }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var overallCard: some View {
        HStack(spacing: 0) {
            overall("\(totalWon)", "Solved")
            Divider().frame(height: 40).background(Brand.hairline)
            overall("\(totalPlayed)", "Played")
            Divider().frame(height: 40).background(Brand.hairline)
            overall(totalPlayed == 0 ? "—" : "\(Int(Double(totalWon) / Double(totalPlayed) * 100))%", "Win rate")
        }
        .glassCard()
    }

    private func overall(_ value: String, _ label: String) -> some View {
        VStack(spacing: 6) {
            Text(value).font(Brand.mono(22, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Solved by difficulty")
            Chart(ordered) { stat in
                BarMark(
                    x: .value("Difficulty", stat.difficulty.rawValue),
                    y: .value("Solved", stat.won)
                )
                .foregroundStyle(stat.difficulty.tint.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis { AxisMarks(position: .leading) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func difficultyCard(_ stat: GameStats) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: stat.difficulty.icon).foregroundStyle(stat.difficulty.tint)
                Text(stat.difficulty.rawValue).font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(Int(stat.winRate * 100))% win").font(Brand.mono(12)).foregroundStyle(Brand.text3)
            }
            HStack(spacing: 0) {
                detail("\(stat.won)", "Solved")
                detail(stat.bestTime == 0 ? "—" : timeString(stat.bestTime), "Best")
                detail(stat.averageTime == 0 ? "—" : timeString(stat.averageTime), "Average")
            }
        }
        .glassCard()
    }

    private func detail(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Brand.mono(15, weight: .semibold)).foregroundStyle(Brand.text)
            Text(label).font(Brand.mono(10)).foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
