import SwiftUI
import SwiftData

/// Status filter including an "All" pseudo-case.
private enum StatusFilter: String, CaseIterable, Identifiable {
    case all, backlog, playing, completed, abandoned, wishlist
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .backlog: return "Backlog"
        case .playing: return "Playing"
        case .completed: return "Done"
        case .abandoned: return "Dropped"
        case .wishlist: return "Wishlist"
        }
    }
    var status: GameStatus? {
        switch self {
        case .all: return nil
        case .backlog: return .backlog
        case .playing: return .playing
        case .completed: return .completed
        case .abandoned: return .abandoned
        case .wishlist: return .wishlist
        }
    }
}

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Game.dateAdded, order: .reverse) private var games: [Game]

    @State private var filter: StatusFilter = .all
    @State private var search = ""
    @State private var sort: LibrarySort = .recentlyAdded
    @State private var showAdd = false
    @State private var paywall: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 150), spacing: 14)]

    private var nowPlaying: [Game] {
        games.filter { $0.status == .playing }
    }

    private var filtered: [Game] {
        var result = games
        if let status = filter.status {
            result = result.filter { $0.status == status }
        }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(q)
                || $0.platform.label.lowercased().contains(q)
                || $0.genre.label.lowercased().contains(q)
            }
        }
        return sortGames(result)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(LibrarySort.allCases) { s in
                                Text(s.label).tag(s)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    .accessibilityLabel("Sort library")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add game")
                }
            }
            .searchable(text: $search, prompt: "Search title, platform, genre")
            .sheet(isPresented: $showAdd) { AddGameView() }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
            .onAppear { sort = settings.defaultLibrarySort }
        }
    }

    @ViewBuilder
    private var content: some View {
        if games.isEmpty {
            EmptyStateView(
                symbol: "tray.full.fill",
                title: "Your library is empty",
                message: "Add the games you own or want to play. Quest will help you conquer the backlog.",
                actionTitle: "Add your first game",
                action: { attemptAdd() }
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !nowPlaying.isEmpty {
                        nowPlayingShelf
                    }

                    statusPicker

                    if filtered.isEmpty {
                        EmptyStateView(
                            symbol: "magnifyingglass",
                            title: "Nothing here",
                            message: "No games match this filter or search. Try a different status or clear your search."
                        )
                        .padding(.top, 30)
                    } else {
                        countLabel
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filtered) { game in
                                NavigationLink(value: game) {
                                    GameGridCell(game: game, style: settings.coverStyle)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game)
            }
        }
    }

    private var nowPlayingShelf: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Now Playing", systemImage: "play.circle.fill")
                .font(Theme.rounded(16, .bold))
                .foregroundStyle(Theme.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nowPlaying) { game in
                        NavigationLink(value: game) {
                            NowPlayingCard(game: game, style: settings.coverStyle, settings: settings)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var statusPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(StatusFilter.allCases) { f in
                    let selected = f == filter
                    Button {
                        Haptics.play(.selection, enabled: settings.hapticsEnabled)
                        filter = f
                    } label: {
                        Text(f.label)
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(selected ? .white : Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? Theme.accent : Theme.surface,
                                        in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: selected ? 0 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
        }
    }

    private var countLabel: some View {
        Text("^[\(filtered.count) game](inflect: true)")
            .font(Theme.rounded(13, .medium))
            .foregroundStyle(Theme.textFaint)
    }

    private func sortGames(_ input: [Game]) -> [Game] {
        switch sort {
        case .recentlyAdded:
            return input.sorted { $0.dateAdded > $1.dateAdded }
        case .title:
            return input.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating:
            return input.sorted { $0.personalRating > $1.personalRating }
        case .hoursLogged:
            return input.sorted { $0.hoursLogged > $1.hoursLogged }
        case .lengthEstimate:
            return input.sorted { $0.mainStoryHours > $1.mainStoryHours }
        }
    }

    private func attemptAdd() {
        if !isPro && games.count >= Pro.freeGameLimit {
            paywall = .gameLimit
            Haptics.play(.warning, enabled: settings.hapticsEnabled)
        } else {
            showAdd = true
        }
    }
}

// MARK: - Cells

private struct GameGridCell: View {
    let game: Game
    let style: CoverStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                GameCover(title: game.title, initials: game.initials,
                          hue: game.coverHue, style: style)
                    .aspectRatio(3.0/4.0, contentMode: .fit)
                VStack(alignment: .trailing, spacing: 4) {
                    if game.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(5)
                            .background(.black.opacity(0.4), in: Circle())
                            .accessibilityHidden(true)
                    }
                    RatingBadge(rating: game.personalRating)
                }
                .padding(6)
            }
            Text(game.title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            StatusChip(status: game.status)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.title), \(game.platform.label), \(game.status.label)")
        .accessibilityHint("Opens game details")
        .accessibilityAddTraits(.isButton)
    }
}

private struct NowPlayingCard: View {
    let game: Game
    let style: CoverStyle
    let settings: AppSettings

    var body: some View {
        HStack(spacing: 12) {
            GameCover(title: game.title, initials: game.initials,
                      hue: game.coverHue, style: style)
                .frame(width: 56, height: 74)
            VStack(alignment: .leading, spacing: 6) {
                Text(game.title)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                if game.mainStoryHours > 0 {
                    ProgressBar(fraction: game.estimatePercent / 100, color: Theme.accent)
                        .frame(width: 140)
                    Text("\(settings.formatHours(game.hoursLogged)) of \(settings.formatHours(game.mainStoryHours))")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Text(settings.formatHours(game.hoursLogged) + " logged")
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(12)
        .frame(width: 240, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Now playing \(game.title)")
        .accessibilityValue(game.mainStoryHours > 0 ? "\(Int(game.estimatePercent)) percent of estimate" : "\(settings.formatHours(game.hoursLogged)) logged")
        .accessibilityHint("Opens game details")
    }
}
