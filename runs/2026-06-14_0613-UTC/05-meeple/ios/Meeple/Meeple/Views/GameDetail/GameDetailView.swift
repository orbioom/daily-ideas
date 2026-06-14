import SwiftUI
import SwiftData

/// Resolves a game by id from the store so NavigationStack value-based links work safely.
struct GameDetailResolver: View {
    let gameID: UUID
    @Query private var games: [BoardGame]

    init(gameID: UUID) {
        self.gameID = gameID
        _games = Query(filter: #Predicate<BoardGame> { $0.id == gameID })
    }

    var body: some View {
        if let game = games.first {
            GameDetailView(game: game)
        } else {
            EmptyStateView(symbol: "questionmark.square.dashed",
                           title: "Game unavailable",
                           message: "This game may have been deleted.")
        }
    }
}

struct GameDetailView: View {
    @Bindable var game: BoardGame
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var showEdit = false
    @State private var showLogPlay = false
    @State private var confirmDelete = false
    @State private var playToEdit: Play?

    private var stats: StatsEngine.GameStats { StatsEngine.gameStats(game) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    header
                    statBlock
                    logButton
                    playsSection
                }
                .padding(16)
            }
        }
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Edit Game", systemImage: "pencil") }
                    Button(role: .destructive) { confirmDelete = true } label: {
                        Label("Delete Game", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
        .sheet(isPresented: $showEdit) { GameEditView(game: game) }
        .sheet(isPresented: $showLogPlay) { LogPlayView(preselectedGame: game) }
        .sheet(item: $playToEdit) { play in LogPlayView(editingPlay: play, preselectedGame: game) }
        .confirmationDialog("Delete \(game.title)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                context.delete(game)
                Haptics.warning(settings.hapticsEnabled)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the game and all \(game.playCount) logged plays.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            GameCover(title: game.title, initials: game.initials,
                      coverHue: game.coverHue, symbol: game.coverSymbol)
                .frame(width: 110, height: 110)
            VStack(alignment: .leading, spacing: 8) {
                Text(game.title).font(Theme.serif(22, .bold)).foregroundStyle(Theme.textPrimary)
                Text("\(game.designer) · \(game.yearPublished)")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Label(game.status.shortLabel, systemImage: game.status.symbol)
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(game.status.color)
                }
                HStack(spacing: 6) {
                    InfoPill(symbol: "person.2.fill", text: game.playerRangeText)
                    InfoPill(symbol: "clock", text: settings.durationUnit.render(game.playTimeMin))
                    InfoPill(symbol: "scalemass", text: settings.showWeightAs.render(game.weight), tint: Theme.accent)
                }
                if game.rating > 0 {
                    InfoPill(symbol: "star.fill", text: "\(game.rating)/10", tint: Theme.warning)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statBlock: some View {
        CardSection("This game") {
            VStack(spacing: 12) {
                HStack {
                    statTile(value: "\(stats.timesPlayed)", label: "Plays")
                    Divider().frame(height: 36)
                    statTile(value: stats.lastPlayed.map { $0.formatted(.dateTime.month(.abbreviated).day()) } ?? "—",
                             label: "Last played")
                    Divider().frame(height: 36)
                    statTile(value: stats.averageDuration > 0 ? settings.durationUnit.render(stats.averageDuration) : "—",
                             label: "Avg time")
                }
                if !stats.perPlayer.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Win rate by player")
                            .font(Theme.rounded(12, .bold)).foregroundStyle(Theme.textSecondary)
                        ForEach(stats.perPlayer) { row in
                            HStack {
                                PlayerChip(name: row.name, initials: initials(row.name), colorHue: row.colorHue, size: 24)
                                Text(row.name).font(Theme.rounded(14)).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text("\(row.wins)W / \(row.playsWithResults)")
                                    .font(Theme.rounded(13)).foregroundStyle(Theme.textSecondary).monospacedDigit()
                                Text(row.ratePercentText)
                                    .font(Theme.rounded(13, .bold)).foregroundStyle(Theme.accent)
                                    .frame(width: 44, alignment: .trailing).monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(row.name): \(row.wins) wins of \(row.playsWithResults) plays, \(row.ratePercentText) win rate")
                        }
                    }
                }
            }
        }
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(Theme.rounded(11)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var logButton: some View {
        Button { showLogPlay = true } label: {
            Label("Log a Play", systemImage: "plus.circle.fill")
                .font(Theme.rounded(17, .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
    }

    @ViewBuilder private var playsSection: some View {
        let plays = game.plays.sorted { $0.date > $1.date }
        CardSection("Play history (\(plays.count))") {
            if plays.isEmpty {
                Text("No plays logged yet. Tap “Log a Play” above.")
                    .font(Theme.rounded(14)).foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 0) {
                    ForEach(plays) { play in
                        PlayRow(play: play, settings: settings)
                            .contentShape(Rectangle())
                            .onTapGesture { playToEdit = play }
                            .swipeActions {
                                Button(role: .destructive) {
                                    context.delete(play)
                                    Haptics.warning(settings.hapticsEnabled)
                                } label: { Label("Delete", systemImage: "trash") }
                            }
                        if play.id != plays.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private func initials(_ name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let j = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        return j.isEmpty ? "?" : j
    }
}

struct PlayRow: View {
    let play: Play
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(play.date.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(Theme.rounded(14, .semibold)).foregroundStyle(Theme.textPrimary)
                HStack(spacing: 4) {
                    ForEach(play.results.prefix(6)) { r in
                        PlayerChip(name: r.playerName, initials: initials(r.playerName),
                                   colorHue: r.colorHue, size: 22)
                            .overlay(alignment: .topTrailing) {
                                if r.isWinner {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 8)).foregroundStyle(Theme.warning)
                                        .offset(x: 2, y: -3)
                                }
                            }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                if !play.winnerNames.isEmpty {
                    Text(play.winnerNames.joined(separator: ", "))
                        .font(Theme.rounded(12, .semibold)).foregroundStyle(Theme.warning)
                        .lineLimit(1)
                }
                if play.durationMin > 0 {
                    Text(settings.durationUnit.render(play.durationMin))
                        .font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summary)
    }

    private var summary: String {
        var parts = [play.date.formatted(.dateTime.month().day().year())]
        parts.append("players: " + play.results.map(\.playerName).joined(separator: ", "))
        if !play.winnerNames.isEmpty { parts.append("winner: " + play.winnerNames.joined(separator: ", ")) }
        if play.durationMin > 0 { parts.append(settings.durationUnit.render(play.durationMin)) }
        return parts.joined(separator: ", ")
    }

    private func initials(_ name: String) -> String {
        let words = name.split(separator: " ").prefix(2)
        let j = words.compactMap { $0.first }.map(String.init).joined().uppercased()
        return j.isEmpty ? "?" : j
    }
}
