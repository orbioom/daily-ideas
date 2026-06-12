import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Game.dateAdded, order: .reverse) private var games: [Game]

    @State private var search = ""
    @State private var filter: GameStatus? = nil
    @State private var sort: SortKey = .recent
    @State private var showAdd = false

    enum SortKey: String, CaseIterable, Identifiable {
        case recent = "Recently added", title = "Title", rating = "Rating", hours = "Hours played"
        var id: String { rawValue }
    }

    private var filtered: [Game] {
        var list = games
        if let filter { list = list.filter { $0.status == filter } }
        if !search.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = search.lowercased()
            list = list.filter { $0.title.lowercased().contains(q) }
        }
        switch sort {
        case .recent: list.sort { $0.dateAdded > $1.dateAdded }
        case .title:  list.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating: list.sort { $0.ratingHalf > $1.ratingHalf }
        case .hours:  list.sort { $0.hoursPlayed > $1.hoursPlayed }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                if games.isEmpty {
                    EmptyStateView(symbol: "square.stack.3d.up.slash",
                                   title: "Your library is empty",
                                   message: "Add the games you own, want, or are playing and Checkpoint will keep score.",
                                   actionTitle: "Add a game") { showAdd = true }
                } else {
                    listBody
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(SortKey.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: { Image(systemName: "arrow.up.arrow.down") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add game")
                }
            }
            .navigationDestination(for: Game.self) { GameDetailView(game: $0) }
            .sheet(isPresented: $showAdd) { GameEditView(game: nil) }
            .searchable(text: $search, prompt: "Search your games")
        }
    }

    private var listBody: some View {
        ScrollView {
            VStack(spacing: 14) {
                filterBar
                if filtered.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "Nothing here for this filter. Try another status or clear your search.")
                        .padding(.top, 30)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { game in
                            NavigationLink(value: game) {
                                GameRow(game: game)
                            }
                            .buttonStyle(.plain)
                            .contextMenu { statusMenu(for: game) }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", count: games.count, selected: filter == nil) { filter = nil }
                ForEach(GameStatus.allCases) { s in
                    let c = BacklogEngine.count(games, status: s)
                    if c > 0 {
                        FilterChip(title: s.label, count: c, selected: filter == s, tint: s.tint) {
                            filter = (filter == s) ? nil : s
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder private func statusMenu(for game: Game) -> some View {
        Menu("Move to…") {
            ForEach(GameStatus.allCases) { s in
                Button { setStatus(game, s) } label: { Label(s.label, systemImage: s.symbol) }
            }
        }
        Button(role: .destructive) { delete(game) } label: { Label("Delete", systemImage: "trash") }
    }

    private func setStatus(_ game: Game, _ s: GameStatus) {
        Haptics.tap()
        game.status = s
        if s == .playing && game.dateStarted == nil { game.dateStarted = Date() }
        if s.isFinished && game.dateFinished == nil { game.dateFinished = Date() }
        try? context.save()
    }
    private func delete(_ game: Game) {
        context.delete(game); try? context.save()
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let selected: Bool
    var tint: Color = Theme.accent
    let action: () -> Void
    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            HStack(spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                Text("\(count)").font(.caption.weight(.bold))
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(selected ? .white.opacity(0.25) : tint.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? tint : Theme.bgElevated, in: Capsule())
            .foregroundStyle(selected ? .white : Theme.textPrimary)
        }
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

struct GameRow: View {
    let game: Game
    var body: some View {
        HStack(spacing: 12) {
            CoverSwatch(game: game, size: 52)
            VStack(alignment: .leading, spacing: 5) {
                Text(game.title)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    StatusPill(status: game.status, compact: true)
                    Text(game.platform.rawValue)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                if game.hoursPlayed > 0 || game.ratingHalf > 0 {
                    HStack(spacing: 8) {
                        if game.hoursPlayed > 0 {
                            Label(Fmt.hours(game.hoursPlayed), systemImage: "clock")
                                .font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                        if game.ratingHalf > 0 {
                            Label(String(format: "%.1f", game.rating), systemImage: "star.fill")
                                .font(.caption2).foregroundStyle(Theme.gold)
                        }
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .cpCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(game.title), \(game.status.label), \(game.platform.rawValue)")
    }
}
