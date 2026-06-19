import SwiftUI
import SwiftData
import Charts

struct ScribeStatsView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var games: [GameRecord]

    private var avgScore: Int {
        guard !games.isEmpty else { return 0 }
        return games.reduce(0) { $0 + $1.score } / games.count
    }

    private var bestScore: Int {
        games.map { $0.score }.max() ?? 0
    }

    private var totalWords: Int {
        games.reduce(0) { $0 + $1.wordsPlayed }
    }

    var body: some View {
        NavigationStack {
            List {
                if games.isEmpty {
                    ContentUnavailableView("No Games Yet", systemImage: "chart.bar", description: Text("Play your first game to see stats here."))
                } else {
                    Section("Overview") {
                        statsGrid
                    }

                    Section("Score History") {
                        Chart(games.prefix(20).reversed().enumerated().map { ($0.offset, $0.element) }, id: \.0) { idx, game in
                            BarMark(x: .value("Game", idx + 1), y: .value("Score", game.score))
                                .foregroundStyle(Color.blue.gradient)
                        }
                        .frame(height: 180)
                        .chartXAxis(.hidden)
                        .padding(.vertical, 8)
                    }

                    Section("Best Words") {
                        ForEach(games.prefix(5)) { game in
                            if !game.highestWord.isEmpty {
                                HStack {
                                    Text(game.highestWord)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(game.highestWordScore) pts")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section("Recent Games") {
                        ForEach(games.prefix(10)) { game in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(game.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                    Text("\(game.wordsPlayed) words")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(game.score) pts")
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "Best Score", value: "\(bestScore)", icon: "trophy.fill", color: .yellow)
            StatCard(title: "Average Score", value: "\(avgScore)", icon: "chart.bar.fill", color: .blue)
            StatCard(title: "Games Played", value: "\(games.count)", icon: "gamecontroller.fill", color: .purple)
            StatCard(title: "Total Words", value: "\(totalWords)", icon: "text.word.spacing", color: .green)
        }
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
