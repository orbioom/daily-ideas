import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(records) { record in
                            GameHistoryRow(record: record)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(records[i]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(DominoTheme.background)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 56))
                .foregroundStyle(DominoTheme.ivory.opacity(0.3))
            Text("No matches yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DominoTheme.ivory)
            Text("Complete a match to see it in your history.")
                .foregroundStyle(DominoTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct GameHistoryRow: View {
    let record: GameRecord

    var resultColor: Color { record.didPlayerWin ? DominoTheme.green : DominoTheme.red }

    var body: some View {
        HStack(spacing: 12) {
            Text(record.didPlayerWin ? "W" : "L")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(resultColor, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("\(record.playerFinalScore) – \(record.aiFinalScore)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DominoTheme.ivory)
                Text("\(record.difficulty.capitalized) · \(record.roundsPlayed) rounds · \(record.formattedDuration)")
                    .font(.caption)
                    .foregroundStyle(DominoTheme.secondaryText)
            }
            Spacer()
            Text(record.date, style: .date)
                .font(.caption2)
                .foregroundStyle(DominoTheme.secondaryText)
        }
        .padding(.vertical, 4)
    }
}
