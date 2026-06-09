import SwiftUI
import SwiftData

struct MatchDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var match: Match

    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                resultCard
                gamesCard
                playersCard
                if let me = match.mySide.first(where: { $0.isMe }) {
                    ratingCard(for: me)
                }
                if !match.location.isEmpty || !match.note.isEmpty {
                    detailsCard
                }
                deleteButton
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(Format.shortDate(match.date))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this match?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete match", role: .destructive) { deleteMatch() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the match and its games. Player ratings are not recalculated.")
        }
    }

    private var resultCard: some View {
        VStack(spacing: 10) {
            Text(match.didWin ? "Victory" : "Defeat")
                .font(.title.weight(.bold))
                .foregroundStyle(match.didWin ? Brand.live : Brand.danger)
            Text(match.gamesLine)
                .font(Brand.mono(40, weight: .bold))
                .foregroundStyle(Brand.text)
            HStack(spacing: 8) {
                TagChip(symbol: match.sport.symbol, label: match.sport.label, tint: match.sport.tint)
                TagChip(symbol: match.format.symbol, label: match.format.label)
                TagChip(symbol: "target", label: "to \(match.pointsToWin)")
            }
            Text(Format.longDate(match.date))
                .font(.caption)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(match.didWin ? "Victory" : "Defeat"), games \(match.gamesLine), \(match.sport.label) \(match.format.label)")
    }

    private var gamesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Games")
            ForEach(match.orderedGames) { game in
                HStack {
                    Text("Game \(game.order + 1)")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text(game.line)
                        .font(Brand.mono(18, weight: .semibold))
                        .foregroundStyle(game.myWon ? Brand.live : Brand.text)
                    Image(systemName: game.myWon ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(game.myWon ? Brand.live : Brand.text3)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Game \(game.order + 1): \(game.myScore) to \(game.oppScore), \(game.myWon ? "won" : "lost")")
                if game.id != match.orderedGames.last?.id {
                    Divider().overlay(Brand.hairline)
                }
            }
        }
        .glassCard()
    }

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Players")
            sideRow(title: "Your side", players: match.mySide, won: match.didWin)
            Divider().overlay(Brand.hairline)
            sideRow(title: "Opponents", players: match.oppSide, won: !match.didWin)
        }
        .glassCard()
    }

    private func sideRow(title: String, players: [Player], won: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.caption.weight(.medium)).foregroundStyle(Brand.text3)
                Spacer()
                if won {
                    Text("Won").font(.caption.weight(.bold)).foregroundStyle(Brand.live)
                }
            }
            ForEach(players) { p in
                HStack(spacing: 10) {
                    PlayerAvatar(initials: p.initials, isMe: p.isMe, size: 32)
                    Text(p.name).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(Format.rating(p.rating))
                        .font(Brand.mono(14)).foregroundStyle(Brand.text2)
                }
            }
            if players.isEmpty {
                Text("—").foregroundStyle(Brand.text3)
            }
        }
    }

    private func ratingCard(for me: Player) -> some View {
        // Show the delta this match contributed for my side, recomputed from the
        // pre-match ratings reconstructed via the rating history series.
        let history = StatsEngine.ratingHistory(for: me, in: allCompleted())
        let delta = matchDelta(in: history)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Rating impact")
            HStack {
                Text("Your rating after this match")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.signedRating(delta))
                    .font(Brand.mono(18, weight: .semibold))
                    .foregroundStyle(delta >= 0 ? Brand.live : Brand.danger)
            }
        }
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rating impact \(Format.signedRating(delta))")
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Details")
            if !match.location.isEmpty {
                LabeledContent("Location", value: match.location)
            }
            if !match.note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note").font(.caption).foregroundStyle(Brand.text3)
                    Text(match.note).font(.subheadline).foregroundStyle(Brand.text)
                }
            }
        }
        .glassCard()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.warning()
            showDeleteConfirm = true
        } label: {
            Label("Delete match", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
        .tint(Brand.danger)
    }

    // MARK: - Helpers

    /// Every completed match, fetched fresh so the rating history is accurate.
    private func allCompleted() -> [Match] {
        let descriptor = FetchDescriptor<Match>(sortBy: [SortDescriptor(\.date)])
        let all = (try? context.fetch(descriptor)) ?? []
        return all.filter { $0.isComplete }
    }

    /// The rating change attributable to this specific match in the history.
    private func matchDelta(in history: [StatsEngine.RatingPoint]) -> Double {
        guard history.count >= 2 else { return 0 }
        // Find the point whose date matches this match's date most closely.
        if let idx = history.firstIndex(where: { abs($0.date.timeIntervalSince(match.date)) < 1 }),
           idx > 0 {
            return history[idx].rating - history[idx - 1].rating
        }
        return history[history.count - 1].rating - history[history.count - 2].rating
    }

    private func deleteMatch() {
        context.delete(match)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
