import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Query(sort: \HoopGame.date, order: .reverse) private var games: [HoopGame]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedGame: HoopGame?

    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()

                if games.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(games) { game in
                            Button {
                                selectedGame = game
                            } label: {
                                GameHistoryRow(game: game)
                            }
                            .listRowBackground(HoopTheme.cardBg)
                            .listRowSeparatorTint(HoopTheme.subtleText.opacity(0.2))
                        }
                        .onDelete(perform: deleteGames)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedGame) { game in
                GameDetailView(game: game)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundColor(HoopTheme.subtleText)
            Text("No Games Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Text("Complete a game and save it to see your history here.")
                .font(.system(size: 15))
                .foregroundColor(HoopTheme.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(games[index])
        }
        try? modelContext.save()
    }
}

struct GameHistoryRow: View {
    let game: HoopGame

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: game.date)
    }

    private var winnerIsA: Bool { game.finalScoreA > game.finalScoreB }
    private var winnerIsB: Bool { game.finalScoreB > game.finalScoreA }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dateString)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(HoopTheme.subtleText)

            HStack(spacing: 12) {
                // Team A
                VStack(alignment: .leading, spacing: 2) {
                    Text(game.teamAName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(winnerIsA ? HoopTheme.teamAColor : HoopTheme.subtleText)
                    Text("\(game.finalScoreA)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(winnerIsA ? .white : HoopTheme.subtleText)
                }

                Spacer()

                Text("vs")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(HoopTheme.subtleText)

                Spacer()

                // Team B
                VStack(alignment: .trailing, spacing: 2) {
                    Text(game.teamBName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(winnerIsB ? HoopTheme.teamBColor : HoopTheme.subtleText)
                    Text("\(game.finalScoreB)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(winnerIsB ? .white : HoopTheme.subtleText)
                }
            }

            if let winner = game.winner {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 10))
                    Text(winner)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(HoopTheme.orange)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GameHistoryView()
        .preferredColorScheme(.dark)
}
