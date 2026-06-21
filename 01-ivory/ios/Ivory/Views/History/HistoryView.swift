import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Environment(\.modelContext) private var ctx

    var body: some View {
        NavigationStack {
            ZStack {
                IvoryTheme.background.ignoresSafeArea()
                Group {
                    if records.isEmpty {
                        EmptyStateView(
                            icon: "clock",
                            title: "No games yet",
                            message: "Play a game and your history will appear here."
                        )
                    } else {
                        List(records) { rec in
                            GameRowView(record: rec)
                                .listRowBackground(IvoryTheme.surface)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !records.isEmpty {
                        Button(role: .destructive) {
                            records.forEach { ctx.delete($0) }
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                        .accessibilityLabel("Clear all game history")
                    }
                }
            }
        }
    }
}

struct GameRowView: View {
    let record: GameRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.playerWon ? "Victory" : record.isDraw ? "Draw" : "Defeat")
                    .font(.headline)
                    .foregroundStyle(record.playerWon ? Color.green : record.isDraw ? IvoryTheme.accent : Color.red)
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(IvoryTheme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("⚫\(record.blackDiscs) – ⚪\(record.whiteDiscs)")
                    .font(.subheadline.bold())
                    .foregroundStyle(IvoryTheme.primaryText)
                Text(record.difficulty.capitalized)
                    .font(.caption2)
                    .foregroundStyle(IvoryTheme.secondaryText)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(record.playerWon ? "Victory" : record.isDraw ? "Draw" : "Defeat"), " +
            "Black \(record.blackDiscs) White \(record.whiteDiscs), " +
            "\(record.difficulty), " +
            "\(record.date.formatted(date: .abbreviated, time: .shortened))"
        )
    }
}
