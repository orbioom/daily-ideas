import SwiftUI
import SwiftData

struct PlayerDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var player: Player
    @Query private var matches: [Match]

    @State private var showEditor = false
    @State private var showDeleteConfirm = false

    private var completed: [Match] { matches.filter { $0.isComplete } }
    private var record: StatsEngine.Record { StatsEngine.record(for: player, in: completed) }
    private var streak: Int { StatsEngine.currentStreak(for: player, in: completed) }
    private var recent: [Match] { Array(StatsEngine.matches(for: player, in: completed).prefix(8)) }
    private var opponents: [StatsEngine.Opponent] { StatsEngine.opponents(for: player, in: completed) }
    private var bestPartner: StatsEngine.Partner? { StatsEngine.bestPartner(for: player, in: completed) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                statsGrid
                if let bestPartner { partnerCard(bestPartner) }
                if !opponents.isEmpty { headToHeadCard }
                recentCard
                if !player.isMe { deleteButton }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { Haptics.tap(); showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            PlayerEditorView(player: player)
        }
        .confirmationDialog("Delete \(player.name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete player", role: .destructive) { deletePlayer() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Past matches are kept but will show this player as removed.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            PlayerAvatar(initials: player.initials, isMe: player.isMe, size: 72)
            Text(Format.rating(player.rating))
                .font(Brand.mono(40, weight: .bold))
                .foregroundStyle(Brand.text)
            Eyebrow(text: "rating")
            if !player.note.isEmpty {
                Text(player.note)
                    .font(.subheadline).foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: record.line, label: "Record")
            StatTile(value: "\(record.winRatePercent)%", label: "Win rate", tint: Brand.live)
            StatTile(value: StatsEngine.streakLabel(streak),
                     label: "Streak", tint: streak >= 0 ? Brand.live : Brand.danger)
            StatTile(value: "\(record.total)", label: "Matches")
        }
    }

    private func partnerCard(_ partner: StatsEngine.Partner) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(text: "Best partner")
            HStack(spacing: 10) {
                PlayerAvatar(initials: partner.player.initials, size: 36)
                Text(partner.player.name).font(.subheadline).foregroundStyle(Brand.text)
                Spacer()
                Text("\(partner.record.line) · \(partner.record.winRatePercent)%")
                    .font(Brand.mono(14)).foregroundStyle(Brand.text2)
            }
        }
        .glassCard()
    }

    private var headToHeadCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Head-to-head")
            ForEach(opponents) { opp in
                HStack(spacing: 10) {
                    PlayerAvatar(initials: opp.player.initials, isMe: opp.player.isMe, size: 30)
                    Text(opp.player.name).font(.subheadline).foregroundStyle(Brand.text)
                    Spacer()
                    Text(opp.record.line)
                        .font(Brand.mono(15, weight: .medium))
                        .foregroundStyle(opp.record.wins >= opp.record.losses ? Brand.live : Brand.danger)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Versus \(opp.player.name): \(opp.record.wins) wins, \(opp.record.losses) losses")
                if opp.id != opponents.last?.id {
                    Divider().overlay(Brand.hairline)
                }
            }
        }
        .glassCard()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Recent matches")
            if recent.isEmpty {
                Text("No completed matches yet.")
                    .font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                ForEach(recent) { m in
                    let won = StatsEngine.didWin(player, m)
                    HStack(spacing: 10) {
                        ResultBadge(didWin: won)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(opponentLabel(for: m))
                                .font(.subheadline).foregroundStyle(Brand.text).lineLimit(1)
                            Text("\(m.sport.label) · \(Format.shortDate(m.date))")
                                .font(.caption).foregroundStyle(Brand.text3)
                        }
                        Spacer()
                        Text(perspectiveGames(for: m))
                            .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(won ? "Win" : "Loss") versus \(opponentLabel(for: m)), \(Format.mediumDate(m.date))")
                }
            }
        }
        .glassCard()
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            Haptics.warning(); showDeleteConfirm = true
        } label: {
            Label("Delete player", systemImage: "trash").frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
        .tint(Brand.danger)
    }

    // MARK: - Helpers

    private func opponentLabel(for match: Match) -> String {
        let opp = StatsEngine.isOnMySide(player, match) ? match.oppSide : match.mySide
        let names = opp.map(\.name).filter { !$0.isEmpty }
        return names.isEmpty ? "Unknown" : "vs " + names.joined(separator: " & ")
    }

    private func perspectiveGames(for match: Match) -> String {
        if StatsEngine.isOnMySide(player, match) {
            return "\(match.myGamesWon)–\(match.oppGamesWon)"
        }
        return "\(match.oppGamesWon)–\(match.myGamesWon)"
    }

    private func deletePlayer() {
        context.delete(player)
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
