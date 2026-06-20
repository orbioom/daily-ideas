import SwiftUI
import SwiftData

struct GameHistoryView: View {
    @Query(sort: \HoopGame.date, order: .reverse) private var games: [HoopGame]
    @Environment(\.modelContext) private var modelContext
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    var body: some View {
        NavigationStack {
            ZStack {
                HoopTheme.darkBg.ignoresSafeArea()
                
                if games.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 56))
                            .foregroundStyle(HoopTheme.subtleText)
                        Text("No Games Yet")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Complete and save a game to see it here.")
                            .font(.subheadline)
                            .foregroundStyle(HoopTheme.subtleText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(games) { game in
                            NavigationLink {
                                GameDetailView(game: game)
                            } label: {
                                gameRow(game: game)
                            }
                            .listRowBackground(HoopTheme.cardBg)
                            .listRowSeparatorTint(Color.white.opacity(0.07))
                        }
                        .onDelete { indices in
                            for idx in indices { modelContext.delete(games[idx]) }
                            try? modelContext.save()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !games.isEmpty {
                    EditButton()
                        .foregroundStyle(HoopTheme.orange)
                }
            }
        }
    }
    
    @ViewBuilder
    func gameRow(game: HoopGame) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dateFormatter.string(from: game.date))
                .font(.caption)
                .foregroundStyle(HoopTheme.subtleText)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(game.teamAName)
                        .font(.headline)
                        .foregroundStyle(game.finalScoreA > game.finalScoreB ? HoopTheme.orange : .white)
                    Text("\(game.finalScoreA)")
                        .font(.title2.bold())
                        .foregroundStyle(game.finalScoreA > game.finalScoreB ? HoopTheme.orange : .white)
                }
                
                Spacer()
                
                Text("vs")
                    .font(.caption)
                    .foregroundStyle(HoopTheme.subtleText)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(game.teamBName)
                        .font(.headline)
                        .foregroundStyle(game.finalScoreB > game.finalScoreA ? HoopTheme.orange : .white)
                    Text("\(game.finalScoreB)")
                        .font(.title2.bold())
                        .foregroundStyle(game.finalScoreB > game.finalScoreA ? HoopTheme.orange : .white)
                }
            }
            
            if game.winnerName != "Tie" {
                Text("\(game.winnerName) wins")
                    .font(.caption.bold())
                    .foregroundStyle(HoopTheme.orange)
            } else {
                Text("Tie game")
                    .font(.caption.bold())
                    .foregroundStyle(HoopTheme.subtleText)
            }
        }
        .padding(.vertical, 4)
    }
}
