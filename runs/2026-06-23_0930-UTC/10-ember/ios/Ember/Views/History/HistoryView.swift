import SwiftUI
import SwiftData

/// History tab: a chronological list of sessions and standalone mood logs, with
/// swipe-to-delete and an entry point to log a mood. Full CRUD on user data.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \BreathSession.startedAt, order: .reverse) private var sessions: [BreathSession]
    @Query(sort: \MoodEntry.date, order: .reverse) private var moods: [MoodEntry]

    @State private var showMoodLogger = false
    @State private var segment: Segment = .sessions

    private enum Segment: String, CaseIterable, Identifiable {
        case sessions = "Sessions"
        case moods = "Mood Log"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch segment {
                case .sessions: sessionList
                case .moods: moodList
                }
            }
            .emberScreenBackground()
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("View", selection: $segment) {
                        ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.shared.tap()
                        showMoodLogger = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log a mood")
                }
            }
            .sheet(isPresented: $showMoodLogger) {
                MoodLoggerSheet()
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: Sessions

    @ViewBuilder
    private var sessionList: some View {
        if sessions.isEmpty {
            ScrollView {
                EmptyStateView(icon: "wind",
                               title: "No sessions yet",
                               message: "Your completed breathing sessions will appear here. Head to the Breathe tab to begin.")
                    .padding()
            }
        } else {
            List {
                ForEach(groupedSessions, id: \.0) { day, items in
                    Section(header: Text(sectionTitle(day)).foregroundStyle(Theme.textSecondary)) {
                        ForEach(items) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                SessionRow(session: session)
                            }
                        }
                        .onDelete { offsets in delete(items: items, at: offsets) }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var groupedSessions: [(Date, [BreathSession])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: sessions) { cal.startOfDay(for: $0.startedAt) }
        return groups.sorted { $0.key > $1.key }
    }

    private func delete(items: [BreathSession], at offsets: IndexSet) {
        Haptics.shared.warning()
        for index in offsets {
            guard items.indices.contains(index) else { continue }
            context.delete(items[index])
        }
        try? context.save()
    }

    // MARK: Moods

    @ViewBuilder
    private var moodList: some View {
        if moods.isEmpty {
            ScrollView {
                EmptyStateView(icon: "face.smiling",
                               title: "No mood logs yet",
                               message: "Tap + to record how you're feeling. Tracking mood helps you see what breathing does for you.",
                               actionTitle: "Log Mood") { showMoodLogger = true }
                    .padding()
            }
        } else {
            List {
                ForEach(moods) { mood in
                    MoodRow(mood: mood)
                }
                .onDelete(perform: deleteMoods)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func deleteMoods(at offsets: IndexSet) {
        Haptics.shared.warning()
        for index in offsets {
            guard moods.indices.contains(index) else { continue }
            context.delete(moods[index])
        }
        try? context.save()
    }

    private func sectionTitle(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

/// One session list row.
private struct SessionRow: View {
    let session: BreathSession
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: session.style.systemImage)
                .foregroundStyle(session.style.accent)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.patternName).font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text("\(session.startedAt.formatted(date: .omitted, time: .shortened)) · \(durationText)")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if let delta = session.moodDelta {
                Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                    .font(.caption.bold())
                    .foregroundStyle(delta > 0 ? Theme.good : (delta < 0 ? Theme.warn : Theme.textSecondary))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.patternName), \(durationText)")
    }
    private var durationText: String {
        let m = Int(session.durationSeconds.rounded()) / 60
        let s = Int(session.durationSeconds.rounded()) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}

/// One standalone mood list row.
private struct MoodRow: View {
    let mood: MoodEntry
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(Mood.emoji(mood.score)).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(Mood.label(mood.score)).font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(mood.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if !mood.note.isEmpty {
                Image(systemName: "text.alignleft").foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Mood.label(mood.score)), \(mood.date.formatted(date: .abbreviated, time: .shortened))")
    }
}

#Preview {
    HistoryView()
        .previewModelContainer()
}
