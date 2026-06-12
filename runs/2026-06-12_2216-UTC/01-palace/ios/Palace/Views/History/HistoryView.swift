import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No Games Yet",
                        systemImage: "suit.club.fill",
                        description: Text("Finish a game on the Play tab and it will appear here — wins and losses alike.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            recordRow(record)
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !records.isEmpty {
                    EditButton()
                }
            }
        }
    }

    private func recordRow(_ record: GameRecord) -> some View {
        HStack(spacing: 14) {
            Image(systemName: record.won ? "crown.fill" : "xmark")
                .font(.headline)
                .foregroundStyle(record.won ? PalaceTheme.gold : Color.secondary)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(record.won ? PalaceTheme.gold.opacity(0.15) : Color(.tertiarySystemFill))
                )
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(record.won ? "Won — \(record.score) points" : "Lost — \(record.score) points")
                    .font(.body.weight(.medium))
                Text("\(record.moves) moves · \(Format.duration(record.durationSeconds)) · Draw \(record.drawThree ? "3" : "1")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.date, format: .dateTime.month(.abbreviated).day())
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(records[index])
        }
    }
}
