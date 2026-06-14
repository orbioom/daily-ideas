import SwiftUI
import SwiftData

struct GameDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Bindable var game: Game

    @State private var showSessionEditor = false
    @State private var editingSession: PlaySession?
    @State private var showDeleteConfirm = false
    @State private var showCelebration = false
    @State private var hoursText = ""
    @State private var editingHours = false

    private var sortedSessions: [PlaySession] {
        game.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    statusCard
                    ratingCard
                    lengthCard
                    sessionsCard
                    notesCard
                    deleteButton
                }
                .padding(16)
            }
            if showCelebration {
                CelebrationOverlay(title: game.title, isShowing: $showCelebration)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: game.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(game.isFavorite ? Theme.danger : Theme.textSecondary)
                }
                .accessibilityLabel(game.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .sheet(isPresented: $showSessionEditor) {
            SessionEditorView(game: game)
        }
        .sheet(item: $editingSession) { session in
            SessionEditorView(game: game, session: session)
        }
        .confirmationDialog("Delete this game?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteGame() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(game.title) and its \(game.sessions.count) logged sessions will be removed. This cannot be undone.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            GameCover(title: game.title, initials: game.initials,
                      hue: game.coverHue, style: settings.coverStyle)
                .frame(width: 96, height: 128)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title)
                    .font(Theme.rounded(20, .heavy))
                    .foregroundStyle(Theme.text)
                Label(game.platform.label, systemImage: game.platform.symbol)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.textSecondary)
                Label(game.genre.label, systemImage: game.genre.symbol)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.textSecondary)
                StatusChip(status: game.status)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Status

    private var statusCard: some View {
        SectionCard(title: "Status", systemImage: "flag.fill") {
            Picker("Status", selection: Binding(
                get: { game.status },
                set: { changeStatus(to: $0) }
            )) {
                ForEach(GameStatus.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)

            if let dc = game.dateCompleted, game.status == .completed {
                Text("Beaten \(dc.formatted(date: .abbreviated, time: .omitted))")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.success)
            }
        }
    }

    // MARK: Rating

    private var ratingCard: some View {
        SectionCard(title: "Your Rating", systemImage: "star.fill") {
            HStack {
                RatingView(rating: Binding(
                    get: { game.personalRating },
                    set: { game.personalRating = $0; save() }
                ), onChange: { _ in
                    Haptics.play(.selection, enabled: settings.hapticsEnabled)
                })
                Spacer()
                Text(game.personalRating == 0 ? "Unrated" : "\(game.personalRating)/10")
                    .font(Theme.mono(15, .bold))
                    .foregroundStyle(game.personalRating == 0 ? Theme.textFaint : Theme.accent)
            }
        }
    }

    // MARK: Length & progress

    private var lengthCard: some View {
        SectionCard(title: "Length & Progress", systemImage: "clock.fill") {
            HStack {
                Text("Length estimate")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if editingHours {
                    TextField("0", text: $hoursText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .font(Theme.mono(15))
                    Text("h").foregroundStyle(Theme.textSecondary)
                    Button("Done") { commitHours() }
                        .font(Theme.rounded(13, .semibold))
                } else {
                    Button {
                        hoursText = game.mainStoryHours > 0 ? trimmed(game.mainStoryHours) : ""
                        editingHours = true
                    } label: {
                        Text(game.mainStoryHours > 0 ? settings.formatHours(game.mainStoryHours) : "Set")
                            .font(Theme.mono(15, .bold))
                            .foregroundStyle(Theme.accent)
                    }
                    .accessibilityLabel("Edit length estimate")
                }
            }

            Divider().overlay(Theme.stroke)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Hours logged")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(settings.formatHours(game.hoursLogged))
                        .font(Theme.mono(15, .bold))
                        .foregroundStyle(Theme.text)
                }
                if game.mainStoryHours > 0 {
                    ProgressBar(fraction: game.estimatePercent / 100)
                    Text("\(Int(game.estimatePercent))% of estimate")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textFaint)
                } else {
                    Text("Add a length estimate to see progress.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textFaint)
                }
            }
        }
    }

    // MARK: Sessions

    private var sessionsCard: some View {
        SectionCard(title: "Play Sessions", systemImage: "list.bullet.rectangle.fill") {
            if sortedSessions.isEmpty {
                VStack(spacing: 10) {
                    Text("No sessions logged yet.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.textSecondary)
                    addSessionButton
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            } else {
                ForEach(sortedSessions) { session in
                    Button {
                        editingSession = session
                    } label: {
                        sessionRow(session)
                    }
                    .buttonStyle(.plain)
                    if session.id != sortedSessions.last?.id {
                        Divider().overlay(Theme.stroke)
                    }
                }
                HStack {
                    Text("Total")
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(settings.formatHours(game.hoursLogged))
                        .font(Theme.mono(15, .bold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 4)
                addSessionButton
            }
        }
    }

    private func sessionRow(_ session: PlaySession) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.text)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(settings.formatHours(session.hours))
                .font(Theme.mono(14, .bold))
                .foregroundStyle(Theme.accent)
            Button {
                deleteSession(session)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.danger)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete session")
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Edit this session")
    }

    private var addSessionButton: some View {
        Button {
            showSessionEditor = true
        } label: {
            Label("Log a session", systemImage: "plus.circle.fill")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .foregroundStyle(Theme.accentDeep)
    }

    // MARK: Notes

    private var notesCard: some View {
        SectionCard(title: "Notes", systemImage: "note.text") {
            TextField("Thoughts, where you left off, tips…",
                      text: Binding(get: { game.notes }, set: { game.notes = $0 }),
                      axis: .vertical)
                .font(Theme.rounded(15))
                .lineLimit(2...8)
                .onChange(of: game.notes) { _, _ in save() }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Label("Delete Game", systemImage: "trash.fill")
                .font(Theme.rounded(15, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .background(Theme.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .foregroundStyle(Theme.danger)
    }

    // MARK: Actions

    private func changeStatus(to newStatus: GameStatus) {
        let wasCompleted = game.status == .completed
        game.status = newStatus
        if newStatus == .completed {
            if game.dateCompleted == nil { game.dateCompleted = .now }
            if !wasCompleted {
                Haptics.play(.success, enabled: settings.hapticsEnabled)
                if settings.celebrateCompletions {
                    showCelebration = true
                }
            }
        } else {
            // Leaving completed clears the beaten date so the challenge stays honest.
            game.dateCompleted = nil
            Haptics.play(.selection, enabled: settings.hapticsEnabled)
        }
        save()
    }

    private func toggleFavorite() {
        game.isFavorite.toggle()
        Haptics.play(.light, enabled: settings.hapticsEnabled)
        save()
    }

    private func commitHours() {
        let cleaned = hoursText.replacingOccurrences(of: ",", with: ".")
        game.mainStoryHours = max(0, Double(cleaned) ?? 0)
        editingHours = false
        save()
    }

    private func deleteSession(_ session: PlaySession) {
        game.sessions.removeAll { $0.id == session.id }
        modelContext.delete(session)
        Haptics.play(.light, enabled: settings.hapticsEnabled)
        save()
    }

    private func deleteGame() {
        modelContext.delete(game)
        try? modelContext.save()
        Haptics.play(.warning, enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func save() {
        try? modelContext.save()
    }

    private func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
