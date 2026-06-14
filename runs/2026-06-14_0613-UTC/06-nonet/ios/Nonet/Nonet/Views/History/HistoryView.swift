import SwiftUI
import SwiftData

/// History of past games plus resumable in-progress saves.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @Query(filter: #Predicate<SavedGame> { $0.isActive == true && $0.completed == false },
           sort: \SavedGame.lastPlayed, order: .reverse) private var active: [SavedGame]

    @State private var launch: GameLaunch? = nil

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty && active.isEmpty {
                    EmptyStateView(icon: "clock",
                                   title: "No History Yet",
                                   message: "Games you play will be listed here with their time and result.")
                } else {
                    List {
                        if !active.isEmpty {
                            Section("In Progress") {
                                ForEach(active) { game in
                                    Button { resume(game) } label: { activeRow(game) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                        if !records.isEmpty {
                            Section("Completed") {
                                ForEach(records) { record in
                                    recordRow(record)
                                }
                                .onDelete(perform: deleteRecords)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("History")
            .fullScreenCover(item: $launch) { GameView(launch: $0) }
        }
    }

    private func resume(_ game: SavedGame) {
        launch = GameLaunch(mode: game.isDaily ? .daily : .casual(game.difficulty),
                            resumeId: game.id)
    }

    private func activeRow(_ game: SavedGame) -> some View {
        HStack(spacing: 12) {
            Image(systemName: game.difficulty.symbol)
                .foregroundStyle(game.difficulty.tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                Text(game.isDaily ? "Daily • \(game.difficulty.title)" : game.difficulty.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                ProgressView(value: game.progress).tint(Theme.accent)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString(game.elapsedSec)).font(Theme.mono(13)).foregroundStyle(Theme.textSecondary)
                Image(systemName: "play.circle.fill").foregroundStyle(Theme.accent)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resume \(game.difficulty.title), \(Int(game.progress * 100)) percent done")
    }

    private func recordRow(_ record: GameRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: record.won ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(record.won ? Theme.success : Theme.error)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.isDaily ? "Daily • \(record.difficulty.title)" : record.difficulty.title)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(dateString(record.date))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeString(record.timeSec))
                    .font(Theme.mono(14, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                if record.mistakes > 0 {
                    Text("\(record.mistakes) mistakes")
                        .font(Theme.rounded(11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Theme.surface)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(record.difficulty.title), \(record.won ? "won" : "lost"), time \(timeString(record.timeSec))")
    }

    private func deleteRecords(_ offsets: IndexSet) {
        for index in offsets where index >= 0 && index < records.count {
            context.delete(records[index])
        }
        try? context.save()
    }

    private func timeString(_ sec: Int) -> String {
        let m = sec / 60, s = sec % 60
        return String(format: "%d:%02d", m, s)
    }
    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: date)
    }
}
