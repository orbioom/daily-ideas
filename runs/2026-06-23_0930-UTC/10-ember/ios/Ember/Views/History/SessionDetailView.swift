import SwiftUI
import SwiftData

/// Detail + edit screen for a single saved session. Supports editing the note and
/// deleting the session (full CRUD).
struct SessionDetailView: View {
    @Bindable var session: BreathSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false
    @State private var editedNote: String = ""
    @State private var isEditing = false

    private var pattern: BreathPattern? { PatternLibrary.pattern(id: session.patternID) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                header
                statsCard
                moodCard
                noteCard
                if let pattern {
                    aboutCard(pattern)
                }
            }
            .padding(Theme.Spacing.md)
        }
        .emberScreenBackground()
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete session")
            }
        }
        .alert("Delete this session?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteSession() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the session from your history.")
        }
        .onAppear { editedNote = session.note }
    }

    private var header: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle().fill(session.style.accent.opacity(0.18)).frame(width: 96, height: 96)
                Image(systemName: session.style.systemImage)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(session.style.accent)
                    .accessibilityHidden(true)
            }
            Text(session.patternName).font(.title2.bold()).foregroundStyle(Theme.textPrimary)
            Text(session.startedAt.formatted(date: .complete, time: .shortened))
                .font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatPill(value: durationText, label: "Duration", systemImage: "hourglass", tint: Theme.deepBlue)
            StatPill(value: "\(session.cyclesCompleted)",
                     label: session.style == .rounds ? "Rounds" : "Cycles",
                     systemImage: "repeat", tint: session.style.accent)
            StatPill(value: session.finished ? "Yes" : "Early",
                     label: "Completed", systemImage: "flag.checkered", tint: session.finished ? Theme.good : Theme.warn)
        }
    }

    @ViewBuilder
    private var moodCard: some View {
        if session.moodBefore > 0 || session.moodAfter > 0 {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SectionHeader(title: "Mood")
                HStack {
                    moodColumn("Before", session.moodBefore)
                    Image(systemName: "arrow.right").foregroundStyle(Theme.textSecondary)
                        .accessibilityHidden(true)
                    moodColumn("After", session.moodAfter)
                    Spacer()
                    if let delta = session.moodDelta {
                        VStack {
                            Text(delta >= 0 ? "+\(delta)" : "\(delta)")
                                .font(.title2.bold())
                                .foregroundStyle(delta > 0 ? Theme.good : (delta < 0 ? Theme.warn : Theme.textSecondary))
                            Text("change").font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
            }
            .emberCard()
        }
    }

    private func moodColumn(_ label: String, _ score: Int) -> some View {
        VStack(spacing: 2) {
            Text(score > 0 ? Mood.emoji(score) : "—").font(.title2)
            Text(label).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(score > 0 ? Mood.label(score) : "not recorded")")
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                SectionHeader(title: "Note")
                Spacer()
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing { saveNote() }
                    isEditing.toggle()
                }
                .font(.subheadline)
            }
            if isEditing {
                TextField("Add a note…", text: $editedNote, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Theme.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            } else {
                Text(session.note.isEmpty ? "No note for this session." : session.note)
                    .font(.subheadline)
                    .foregroundStyle(session.note.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .emberCard()
    }

    private func aboutCard(_ pattern: BreathPattern) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "About \(pattern.name)", subtitle: pattern.rhythmLabel)
            Text(pattern.detail)
                .font(.subheadline).foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .emberCard()
    }

    private var durationText: String {
        let m = Int(session.durationSeconds.rounded()) / 60
        let s = Int(session.durationSeconds.rounded()) % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }

    private func saveNote() {
        session.note = editedNote.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
        Haptics.shared.tap()
    }

    private func deleteSession() {
        Haptics.shared.warning()
        context.delete(session)
        try? context.save()
        dismiss()
    }
}
