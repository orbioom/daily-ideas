import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    private var bestEver: GameResult? { results.max { $0.score < $1.score } }
    private var byDeck: [(deck: String, games: Int, best: Int)] {
        let grouped = Dictionary(grouping: results, by: \.deckName)
        return grouped.map { (deck: $0.key, games: $0.value.count, best: $0.value.map(\.score).max() ?? 0) }
            .sorted { $0.games > $1.games }
    }

    var body: some View {
        NavigationStack {
            Group {
                if results.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: "No rounds played",
                        message: "Grab some friends, pick a deck and play a round — saved scores and bragging rights land here."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            headlineRow
                            deckChart
                            recentList
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("Scores")
        }
    }

    private var headlineRow: some View {
        HStack(spacing: 12) {
            statTile("\(results.count)", "rounds")
            statTile("\(bestEver?.score ?? 0)", "best score")
            statTile("\(results.reduce(0) { $0 + $1.score })", "total guessed")
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .black))
                .foregroundStyle(Theme.accent)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .rompCard()
        .accessibilityElement(children: .combine)
    }

    private var deckChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Best score by deck")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Chart(byDeck, id: \.deck) { item in
                BarMark(
                    x: .value("Best", item.best),
                    y: .value("Deck", item.deck)
                )
                .foregroundStyle(Theme.accent.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text("\(item.best)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .frame(height: max(120, CGFloat(byDeck.count) * 34))
            .accessibilityLabel("Bar chart of best score per deck")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rompCard()
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recent rounds")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.bottom, 6)
            ForEach(results.prefix(25)) { result in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.deckName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("\(result.date.formatted(date: .abbreviated, time: .shortened)) · \(result.roundSeconds)s round")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text("\(result.score)/\(result.totalSeen)")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.vertical, 7)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(result.deckName), scored \(result.score) of \(result.totalSeen)")
                .contextMenu {
                    Button(role: .destructive) {
                        context.delete(result)
                    } label: {
                        Label("Delete round", systemImage: "trash")
                    }
                }
                Divider()
            }
        }
        .rompCard()
    }
}
