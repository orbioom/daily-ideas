import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GameRecord.date, order: .reverse) private var records: [GameRecord]
    @State private var filter: GameMode? = nil

    private var filtered: [GameRecord] {
        guard let filter else { return records }
        return records.filter { $0.mode == filter }
    }

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No games yet",
                        message: "Finished games show up here with scores, players and the winner."
                    )
                } else {
                    List {
                        Section {
                            filterBar
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                        }
                        if filtered.isEmpty {
                            Text("No \(filter?.rawValue ?? "") games yet.")
                                .font(Theme.rounded(15))
                                .foregroundStyle(Theme.inkSoft)
                                .listRowBackground(Theme.surface)
                        } else {
                            ForEach(filtered) { record in
                                NavigationLink {
                                    HistoryDetailView(record: record)
                                } label: {
                                    HistoryRow(record: record)
                                }
                                .listRowBackground(Theme.surface)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, label: "All")
                ForEach(GameMode.allCases) { mode in
                    chip(mode, label: mode.rawValue)
                }
            }
        }
    }

    private func chip(_ mode: GameMode?, label: String) -> some View {
        let selected = filter == mode
        return Button {
            filter = mode
        } label: {
            Text(label)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(selected ? .white : Theme.ink)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? Theme.accent : Theme.surfaceAlt, in: Capsule())
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            if filtered.indices.contains(index) {
                context.delete(filtered[index])
            }
        }
        try? context.save()
    }
}

struct HistoryRow: View {
    let record: GameRecord

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(record.didWin ? Theme.accentSoft : Theme.surfaceAlt)
                    .frame(width: 44, height: 44)
                Image(systemName: record.mode.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(record.didWin ? Theme.accent : Theme.inkSoft)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(record.mode.rawValue)
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.ink)
                    if record.didWin {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.gold)
                    }
                }
                Text(shortDate(record.date) + " · " + record.playerNames.joined(separator: ", "))
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(record.myScore)")
                    .font(Theme.rounded(19, .bold))
                    .foregroundStyle(Theme.accent)
                Text("you")
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.mode.rawValue) on \(shortDate(record.date)). You scored \(record.myScore). \(record.didWin ? "You won." : "Winner \(record.winnerName).")")
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}
