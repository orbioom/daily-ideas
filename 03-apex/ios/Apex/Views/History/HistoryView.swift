import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \GameResult.date, order: .reverse) private var results: [GameResult]

    var body: some View {
        Group {
            if results.isEmpty {
                ContentUnavailableView {
                    Label("No Games Yet", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Your game history will appear here after your first game.")
                }
            } else {
                List {
                    ForEach(results) { result in
                        GameHistoryRow(result: result)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct GameHistoryRow: View {
    let result: GameResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.won ? "trophy.fill" : "xmark.circle")
                .font(.title2)
                .foregroundStyle(result.won ? ApexTheme.gold : Color.secondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(result.date, style: .date)
                    .font(.apexBody())
                Text(result.date, style: .time)
                    .font(.apexCaption())
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(result.score)")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundStyle(result.won ? ApexTheme.gold : .primary)
                Text("\(result.moves) moves")
                    .font(.apexCaption())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.won ? "Won" : "Lost"), score \(result.score), \(result.moves) moves, \(result.date.formatted(date: .abbreviated, time: .shortened))")
    }
}
