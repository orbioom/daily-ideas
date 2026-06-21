import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \EuchreGameRecord.date, order: .reverse) private var records: [EuchreGameRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Games Yet",
                        message: "Complete a game to see your history here."
                    )
                } else {
                    List(records) { record in
                        HistoryRowView(record: record)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
        }
    }
}

struct HistoryRowView: View {
    let record: EuchreGameRecord

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.date, style: .date)
                    .font(.subheadline.bold())
                Text(record.date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("\(record.humanTeamScore) — \(record.aiTeamScore)")
                    .font(.headline.bold())
                Text("\(record.handsPlayed) hands")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(record.humanTeamWon ? "WIN" : "LOSS")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(record.humanTeamWon ? Color.green : Color.red)
                    .clipShape(Capsule())

                Text(record.difficulty)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
