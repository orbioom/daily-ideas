import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \TrainingRecord.date, order: .reverse) private var records: [TrainingRecord]

    private var groupedBySession: [(sessionId: String, date: Date, records: [TrainingRecord])] {
        var dict: [String: [TrainingRecord]] = [:]
        for r in records {
            dict[r.sessionId, default: []].append(r)
        }
        return dict.map { (sessionId: $0.key, date: $0.value.first?.date ?? .distantPast, records: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.badge.questionmark",
                        title: "No History Yet",
                        subtitle: "Your training sessions will appear here once you start practicing."
                    )
                } else {
                    List {
                        ForEach(groupedBySession, id: \.sessionId) { group in
                            Section {
                                ForEach(group.records) { record in
                                    HistoryRowView(record: record)
                                }
                            } header: {
                                SessionHeaderView(date: group.date, records: group.records)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
        }
    }
}

struct SessionHeaderView: View {
    let date: Date
    let records: [TrainingRecord]

    private var accuracy: Double {
        records.isEmpty ? 0 : Double(records.filter(\.isCorrect).count) / Double(records.count)
    }

    private var accuracyColor: Color {
        accuracy >= 0.80 ? CountTheme.correctGreen : (accuracy >= 0.60 ? .yellow : CountTheme.wrongRed)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(date, style: .date)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                Text(date, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(accuracy * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(accuracyColor)
                Text("\(records.filter(\.isCorrect).count)/\(records.count) correct")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.vertical, 4)
    }
}

struct HistoryRowView: View {
    let record: TrainingRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(record.isCorrect ? CountTheme.correctGreen : CountTheme.wrongRed)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.scenario)
                    .font(.system(.subheadline, design: .monospaced).bold())

                HStack(spacing: 6) {
                    Text("Played: \(record.chosenAction)")
                        .font(.caption)
                        .foregroundStyle(record.isCorrect ? .secondary : CountTheme.wrongRed)

                    if !record.isCorrect {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("Correct: \(record.correctAction)")
                            .font(.caption)
                            .foregroundStyle(CountTheme.correctGreen)
                    }
                }
            }

            Spacer()

            Text(record.date, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
