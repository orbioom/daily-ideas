import SwiftUI
import SwiftData

struct FarkleHistoryView: View {
    @Query(sort: \FarkleGame.date, order: .reverse) private var games: [FarkleGame]
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            Group {
                if games.isEmpty {
                    ContentUnavailableView("No Games Yet", systemImage: "die.face.5",
                        description: Text("Complete a game on the Play tab to see your history."))
                } else {
                    List {
                        ForEach(games) { g in
                            HStack(spacing: 14) {
                                Image(systemName: g.outcome == "win" ? "trophy.fill" : "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(g.outcome == "win" ? Color.yellow : Color.red)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(g.outcome == "win" ? "You Won" : "AI Won")
                                        .font(.subheadline.weight(.semibold))
                                    Text("Score: \(g.finalScore) · \(g.turnsPlayed) turns · Goal: \(g.targetScore)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(g.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.map { games[$0] }.forEach { ctx.delete($0) }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar { if !games.isEmpty { EditButton() } }
        }
    }
}
