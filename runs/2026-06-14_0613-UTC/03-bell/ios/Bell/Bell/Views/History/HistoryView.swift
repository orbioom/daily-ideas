import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(
                        symbol: "list.bullet.rectangle",
                        title: "No sits yet",
                        message: "Your meditation log will appear here. Begin a sit from the Today tab."
                    )
                } else {
                    List {
                        ForEach(grouped, id: \.key) { group in
                            Section(group.key) {
                                ForEach(group.value) { session in
                                    NavigationLink {
                                        SessionDetailView(session: session)
                                    } label: {
                                        HistoryRow(session: session)
                                    }
                                }
                                .onDelete { offsets in delete(group.value, offsets) }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("History")
        }
    }

    /// Group sessions by month label, preserving the reverse-chronological order.
    private var grouped: [(key: String, value: [MeditationSession])] {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        var order: [String] = []
        var map: [String: [MeditationSession]] = [:]
        for s in sessions {
            let key = fmt.string(from: s.date)
            if map[key] == nil { order.append(key); map[key] = [] }
            map[key]?.append(s)
        }
        return order.map { ($0, map[$0] ?? []) }
    }

    private func delete(_ items: [MeditationSession], _ offsets: IndexSet) {
        for i in offsets where i < items.count {
            context.delete(items[i])
        }
        try? context.save()
    }
}

// MARK: - Row
private struct HistoryRow: View {
    let session: MeditationSession

    var body: some View {
        HStack(spacing: 14) {
            Text(session.mood.emoji)
                .font(.system(size: 26))
                .frame(width: 38)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(session.durationLabel)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    if !session.completedFully {
                        Text("ended early")
                            .font(Theme.rounded(10, .medium))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.separator)
                            .foregroundStyle(Theme.textSecondary)
                            .clipShape(Capsule())
                    }
                }
                Text(session.presetName)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.textSecondary)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(session.date, format: .dateTime.hour().minute())
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(session.mood.displayName), \(session.durationLabel), \(session.presetName)")
        .accessibilityValue(session.note.isEmpty ? "" : "Note: \(session.note)")
    }
}
