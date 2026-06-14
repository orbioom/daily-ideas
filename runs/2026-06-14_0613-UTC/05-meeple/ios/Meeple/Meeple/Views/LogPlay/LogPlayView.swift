import SwiftUI
import SwiftData

/// Working row for a participant while logging a play.
private struct ParticipantDraft: Identifiable {
    let id = UUID()
    var name: String
    var colorHue: Int
    var scoreText: String = ""
    var isWinner: Bool = false

    var score: Int? { Int(scoreText.trimmingCharacters(in: .whitespaces)) }
}

struct LogPlayView: View {
    // Either edit an existing play, or create a new one (optionally pre-bound to a game).
    var editingPlay: Play? = nil
    var preselectedGame: BoardGame? = nil

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \BoardGame.title) private var allGames: [BoardGame]
    @Query(sort: \Player.createdAt) private var roster: [Player]

    @State private var selectedGameID: UUID?
    @State private var date = Date()
    @State private var durationText = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var participants: [ParticipantDraft] = []
    @State private var quickAddName = ""
    @State private var error: String?
    @State private var loaded = false

    private var ownedGames: [BoardGame] {
        allGames.filter { $0.status == .owned || $0.status == .wantToPlay }
    }
    private var selectedGame: BoardGame? {
        allGames.first { $0.id == selectedGameID }
    }
    private var canSave: Bool { selectedGameID != nil && !participants.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                gameSection
                participantsSection
                quickAddSection
                detailsSection
                if let error {
                    Section { Text(error).font(Theme.rounded(13)).foregroundStyle(Theme.danger) }
                }
            }
            .navigationTitle(editingPlay == nil ? "Log Play" : "Edit Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: loadOnce)
            .onChange(of: participants.map(\.scoreText)) { _, _ in autoResolveWinners() }
        }
    }

    // MARK: Sections

    @ViewBuilder private var gameSection: some View {
        Section("Game") {
            if editingPlay != nil || preselectedGame != nil {
                HStack {
                    Text(selectedGame?.title ?? "—").font(Theme.rounded(16, .semibold))
                    Spacer()
                    if editingPlay == nil && preselectedGame == nil {
                        Image(systemName: "chevron.up.chevron.down").foregroundStyle(Theme.textSecondary)
                    }
                }
            } else if ownedGames.isEmpty {
                Text("Add an owned game first.").foregroundStyle(Theme.textSecondary)
            } else {
                Picker("Game", selection: $selectedGameID) {
                    Text("Choose…").tag(UUID?.none)
                    ForEach(ownedGames) { g in Text(g.title).tag(UUID?.some(g.id)) }
                }
            }
        }
    }

    private var participantsSection: some View {
        Section {
            if participants.isEmpty {
                Text("Add at least one player from your roster below.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
            }
            ForEach($participants) { $p in
                HStack(spacing: 10) {
                    PlayerChip(name: p.name, initials: initials(p.name), colorHue: p.colorHue, size: 30)
                    Text(p.name).font(Theme.rounded(15)).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    TextField("Score", text: $p.scoreText)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .frame(width: 64).font(Theme.rounded(15)).monospacedDigit()
                        .accessibilityLabel("\(p.name) score")
                    Button {
                        toggleWinner(p.id)
                    } label: {
                        Image(systemName: p.isWinner ? "crown.fill" : "crown")
                            .foregroundStyle(p.isWinner ? Theme.warning : Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(p.isWinner ? "\(p.name) marked winner" : "Mark \(p.name) winner")
                }
                .swipeActions {
                    Button(role: .destructive) { remove(p.id) } label: { Label("Remove", systemImage: "trash") }
                }
            }
            if !roster.isEmpty {
                rosterPicker
            }
        } header: {
            Text("Players \(participants.isEmpty ? "" : "(\(participants.count))")")
        } footer: {
            Text(winnerRuleFooter).font(Theme.rounded(12))
        }
    }

    private var rosterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(roster) { player in
                    let added = participants.contains { $0.name == player.name }
                    Button {
                        if added { removeByName(player.name) } else { addPlayer(player) }
                        Haptics.selection(settings.hapticsEnabled)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                            Text(player.name).font(Theme.rounded(13, .semibold))
                        }
                        .foregroundStyle(added ? .white : Theme.textPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(added ? Theme.accent : Theme.surfaceAlt))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var quickAddSection: some View {
        Section("Quick add player") {
            HStack {
                TextField("Name", text: $quickAddName)
                Button("Add") {
                    let n = quickAddName.trimmingCharacters(in: .whitespaces)
                    guard !n.isEmpty else { return }
                    let p = Player(name: n)
                    context.insert(p)
                    addPlayer(p)
                    quickAddName = ""
                    Haptics.tap(settings.hapticsEnabled)
                }
                .disabled(quickAddName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            DatePicker("Date", selection: $date, displayedComponents: .date)
            HStack {
                Text("Duration")
                Spacer()
                TextField("min", text: $durationText)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).frame(width: 80)
                Text("min").foregroundStyle(Theme.textSecondary)
            }
            TextField("Location", text: $location)
            TextField("Notes", text: $notes, axis: .vertical).lineLimit(1...4)
        }
    }

    private var winnerRuleFooter: String {
        switch settings.winnerRule {
        case .highestScore: return "Winner auto-marked: highest score. Tap a crown to override."
        case .lowestScore: return "Winner auto-marked: lowest score. Tap a crown to override."
        case .manual: return "Tap a crown to mark winners. Ties allowed."
        }
    }

    // MARK: Logic

    private func loadOnce() {
        guard !loaded else { return }
        loaded = true
        if let editingPlay {
            selectedGameID = editingPlay.game?.id
            date = editingPlay.date
            durationText = editingPlay.durationMin > 0 ? "\(editingPlay.durationMin)" : ""
            location = editingPlay.location
            notes = editingPlay.notes
            participants = editingPlay.results.map {
                ParticipantDraft(name: $0.playerName, colorHue: $0.colorHue,
                                 scoreText: $0.score.map(String.init) ?? "",
                                 isWinner: $0.isWinner)
            }
        } else if let preselectedGame {
            selectedGameID = preselectedGame.id
            durationText = preselectedGame.playTimeMin > 0 ? "\(preselectedGame.playTimeMin)" : ""
            // Pre-add "me" if present.
            if let me = roster.first(where: { $0.isMe }) { addPlayer(me) }
        }
    }

    private func addPlayer(_ player: Player) {
        guard !participants.contains(where: { $0.name == player.name }) else { return }
        participants.append(ParticipantDraft(name: player.name, colorHue: player.colorHue))
        autoResolveWinners()
    }

    private func remove(_ id: UUID) {
        participants.removeAll { $0.id == id }
        autoResolveWinners()
    }
    private func removeByName(_ name: String) {
        participants.removeAll { $0.name == name }
        autoResolveWinners()
    }

    private func toggleWinner(_ id: UUID) {
        guard let idx = participants.firstIndex(where: { $0.id == id }) else { return }
        participants[idx].isWinner.toggle()
        Haptics.selection(settings.hapticsEnabled)
    }

    /// Auto-resolve winners from scores per the active rule (no-op for manual).
    private func autoResolveWinners() {
        guard settings.winnerRule != .manual else { return }
        let scores = participants.map { $0.score }
        let winners = WinnerResolver.winningIndices(scores: scores, rule: settings.winnerRule)
        guard !winners.isEmpty else { return }
        for i in participants.indices { participants[i].isWinner = winners.contains(i) }
    }

    private func save() {
        guard let game = selectedGame else {
            error = "Please choose a game."; Haptics.warning(settings.hapticsEnabled); return
        }
        guard !participants.isEmpty else {
            error = "Add at least one player."; Haptics.warning(settings.hapticsEnabled); return
        }

        let duration = Int(durationText.trimmingCharacters(in: .whitespaces)) ?? 0

        if let editingPlay {
            // Replace results in place.
            for r in editingPlay.results { context.delete(r) }
            editingPlay.results = []
            editingPlay.date = date
            editingPlay.durationMin = max(0, duration)
            editingPlay.location = location.trimmingCharacters(in: .whitespaces)
            editingPlay.notes = notes
            editingPlay.game = game
            var newResults: [PlayerResult] = []
            for p in participants {
                let r = PlayerResult(playerName: p.name, score: p.score,
                                     isWinner: p.isWinner, colorHue: p.colorHue, play: editingPlay)
                context.insert(r)
                newResults.append(r)
            }
            editingPlay.results = newResults
        } else {
            let play = Play(date: date, durationMin: max(0, duration),
                            location: location.trimmingCharacters(in: .whitespaces),
                            notes: notes, game: game)
            context.insert(play)
            var newResults: [PlayerResult] = []
            for p in participants {
                let r = PlayerResult(playerName: p.name, score: p.score,
                                     isWinner: p.isWinner, colorHue: p.colorHue, play: play)
                context.insert(r)
                newResults.append(r)
            }
            play.results = newResults
        }

        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }

    private func initials(_ name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let j = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        return j.isEmpty ? "?" : j
    }
}
