import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    private var totalGames: Int { results.count }
    private var wins: Int { results.filter { $0.won }.count }
    private var winRate: Double { totalGames == 0 ? 0 : Double(wins) / Double(totalGames) }
    private var bestScore: Int { results.map { $0.score }.max() ?? 0 }
    private var avgScore: Double {
        guard !results.isEmpty else { return 0 }
        return Double(results.map { $0.score }.reduce(0, +)) / Double(results.count)
    }
    private var currentStreak: Int {
        var streak = 0
        for r in results {
            if r.won { streak += 1 } else { break }
        }
        return streak
    }
    private var last30: [GameResult] { Array(results.prefix(30).reversed()) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stat cards row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    statCard("Games Played", value: "\(totalGames)", icon: "gamecontroller.fill")
                    statCard("Win Rate", value: String(format: "%.0f%%", winRate * 100), icon: "trophy.fill", color: .yellow)
                    statCard("Best Score", value: "\(bestScore)", icon: "star.fill", color: ApexTheme.gold)
                    statCard("Avg Score", value: String(format: "%.0f", avgScore), icon: "chart.line.uptrend.xyaxis")
                    statCard("Win Streak", value: "\(currentStreak)", icon: "flame.fill", color: .orange)
                    statCard("Total Wins", value: "\(wins)", icon: "checkmark.seal.fill", color: .green)
                }
                .padding(.horizontal)

                if last30.count > 1 {
                    // Score trend chart
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Scores")
                            .font(.apexBody().bold())
                            .padding(.horizontal)
                        Chart(last30.enumerated().map { ($0.offset, $0.element) }, id: \.0) { idx, result in
                            BarMark(
                                x: .value("Game", idx),
                                y: .value("Score", result.score)
                            )
                            .foregroundStyle(result.won ? ApexTheme.gold : Color.red.opacity(0.6))
                            .cornerRadius(4)
                        }
                        .frame(height: 160)
                        .padding(.horizontal)
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .leading) { _ in
                                AxisValueLabel().foregroundStyle(.secondary)
                                AxisGridLine()
                            }
                        }

                        HStack(spacing: 16) {
                            legendDot(color: ApexTheme.gold, label: "Win")
                            legendDot(color: .red.opacity(0.6), label: "Loss")
                        }
                        .font(.apexCaption())
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                } else {
                    emptyChart
                }

                // Recent games list
                if !results.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Recent Games")
                            .font(.apexBody().bold())
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        ForEach(results.prefix(10)) { result in
                            HStack {
                                Image(systemName: result.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.won ? .green : .red)
                                Text(result.date, style: .date)
                                    .font(.apexBody())
                                Spacer()
                                Text("\(result.score) pts")
                                    .font(.apexBody())
                                    .foregroundStyle(ApexTheme.gold)
                                Text("· \(result.moves)m")
                                    .font(.apexCaption())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            Divider().padding(.horizontal)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color = .primary) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.system(size: 22, weight: .bold, design: .serif)).foregroundStyle(color)
            Text(title).font(.apexCaption()).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }

    private var emptyChart: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis").font(.largeTitle).foregroundStyle(ApexTheme.gold.opacity(0.5))
            Text("Play some games to see your score trend!")
                .font(.apexBody()).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(40)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }
}
