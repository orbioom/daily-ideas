import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MeditationSession.date, order: .reverse) private var sessions: [MeditationSession]

    private var grouped: [(day: Date, items: [MeditationSession])] {
        let cal = Calendar.current
        let dict = Dictionary(grouping: sessions) { cal.startOfDay(for: $0.date) }
        return dict.map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    EmptyStateView(icon: "calendar",
                                   title: "No sits yet",
                                   message: "Your finished sits will appear here, grouped by day.")
                        .padding(20)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Brand.pageBackground)
                } else {
                    List {
                        ForEach(grouped, id: \.day) { group in
                            Section {
                                ForEach(group.items) { session in
                                    row(session)
                                }
                                .onDelete { offsets in
                                    delete(offsets, in: group.items)
                                }
                            } header: {
                                Text(Format.relativeDay(group.day))
                                    .foregroundStyle(Brand.text2)
                            }
                            .listRowBackground(Color.white.opacity(0.001))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(Brand.pageBackground)
                }
            }
            .navigationTitle("History")
        }
    }

    private func row(_ session: MeditationSession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.presetName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Brand.text)
                HStack(spacing: 8) {
                    Text(Format.duration(session.actualSeconds))
                        .font(Brand.mono(13))
                        .foregroundStyle(Brand.text2)
                    if !session.completed {
                        Text("ended early")
                            .font(.caption)
                            .foregroundStyle(Brand.warn)
                    }
                }
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .lineLimit(2)
                }
            }
            Spacer()
            if session.feeling > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<session.feeling, id: \.self) { _ in
                        Circle().fill(Brand.live).frame(width: 6, height: 6)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.presetName), \(Format.duration(session.actualSeconds))\(session.completed ? "" : ", ended early")")
    }

    private func delete(_ offsets: IndexSet, in items: [MeditationSession]) {
        for index in offsets where items.indices.contains(index) {
            context.delete(items[index])
        }
        try? context.save()
        Haptics.warning()
    }
}
