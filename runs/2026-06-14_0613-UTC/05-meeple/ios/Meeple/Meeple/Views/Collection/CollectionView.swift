import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var games: [BoardGame]

    @State private var search = ""
    @State private var statusFilter: CollectionStatus? = .owned
    @State private var sort: CollectionSort = .recent
    @State private var sortInitialised = false
    @State private var showAdd = false
    @State private var paywall: PaywallReason?

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14)]

    private var ownedCount: Int { games.filter { $0.status == .owned }.count }
    private var atFreeLimit: Bool { !isPro && games.count >= Pro.freeGameLimit }

    private var filtered: [BoardGame] {
        var list = games
        if let statusFilter { list = list.filter { $0.status == statusFilter } }
        let q = search.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(q) ||
                $0.designer.localizedCaseInsensitiveContains(q)
            }
        }
        return sorted(list)
    }

    private func sorted(_ list: [BoardGame]) -> [BoardGame] {
        switch sort {
        case .recent: return list.sorted { $0.createdAt > $1.createdAt }
        case .name: return list.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .rating: return list.sorted { $0.rating > $1.rating }
        case .plays: return list.sorted { $0.playCount > $1.playCount }
        case .weight: return list.sorted { $0.weight > $1.weight }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { sortMenu }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if atFreeLimit { paywall = .gameLimit } else { showAdd = true }
                    } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add game")
                }
            }
            .searchable(text: $search, prompt: "Search games or designers")
            .sheet(isPresented: $showAdd) {
                GameEditView(game: nil)
            }
            .sheet(item: $paywall) { reason in PaywallView(reason: reason) }
        }
        .onAppear {
            if !sortInitialised { sort = settings.defaultCollectionSort; sortInitialised = true }
        }
    }

    @ViewBuilder private var content: some View {
        if games.isEmpty {
            EmptyStateView(
                symbol: "square.grid.2x2",
                title: "No games yet",
                message: "Add the board games you own to start cataloguing and logging plays.",
                actionTitle: "Add a game",
                action: { showAdd = true }
            )
        } else {
            VStack(spacing: 0) {
                statusBar
                if filtered.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "Nothing matches",
                        message: "Try a different filter or search term."
                    )
                    Spacer()
                } else {
                    ScrollView {
                        if !isPro {
                            limitBanner
                        }
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filtered) { game in
                                NavigationLink(value: game.id) {
                                    GameGridCell(game: game, settings: settings)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 24)
                    }
                    .navigationDestination(for: UUID.self) { id in
                        GameDetailResolver(gameID: id)
                    }
                }
            }
        }
    }

    private var statusBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(nil, label: "All", count: games.count)
                ForEach(CollectionStatus.allCases) { st in
                    filterChip(st, label: st.shortLabel,
                               count: games.filter { $0.status == st }.count)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
    }

    private func filterChip(_ status: CollectionStatus?, label: String, count: Int) -> some View {
        let active = statusFilter == status
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { statusFilter = status }
            Haptics.selection(settings.hapticsEnabled)
        } label: {
            HStack(spacing: 5) {
                Text(label).font(Theme.rounded(13, .semibold))
                Text("\(count)").font(Theme.rounded(12, .bold)).opacity(0.7)
            }
            .foregroundStyle(active ? .white : Theme.textPrimary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(active ? Theme.accent : Theme.surface))
        }
        .accessibilityLabel("\(label), \(count) games")
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(CollectionSort.allCases) { s in Text(s.label).tag(s) }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .accessibilityLabel("Sort, current \(sort.label)")
    }

    private var limitBanner: some View {
        let remaining = max(0, Pro.freeGameLimit - games.count)
        return Group {
            if atFreeLimit {
                banner(text: "Free limit reached (\(Pro.freeGameLimit) games). Go Pro for unlimited.",
                       cta: "Upgrade") { paywall = .gameLimit }
            } else if games.count >= Pro.freeGameLimit - 3 {
                banner(text: "\(remaining) game slots left on the free tier.",
                       cta: "Go Pro") { paywall = .gameLimit }
            }
        }
    }

    private func banner(text: String, cta: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(text).font(Theme.rounded(13, .medium)).foregroundStyle(Theme.textPrimary)
            Spacer()
            Button(cta, action: action).font(Theme.rounded(13, .bold))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: Theme.cornerMedium).fill(Theme.accentSoft.opacity(0.5)))
        .padding(.horizontal, 16).padding(.top, 8)
    }
}

// MARK: - Grid cell

private struct GameGridCell: View {
    let game: BoardGame
    let settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                GameCover(title: game.title, initials: game.initials,
                          coverHue: game.coverHue, symbol: game.coverSymbol)
                    .aspectRatio(1.0, contentMode: .fit)
                if game.playCount > 0 {
                    Text("\(game.playCount)×")
                        .font(Theme.rounded(11, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.45)))
                        .padding(6)
                }
            }
            Text(game.title)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            HStack(spacing: 6) {
                InfoPill(symbol: "person.2.fill", text: game.playerRangeText)
                InfoPill(symbol: "clock", text: "\(game.playTimeMin)m")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Opens game detail")
    }

    private var accessibilitySummary: String {
        var parts = [game.title, "\(game.playerRangeText) players", "\(game.playTimeMin) minutes"]
        if game.playCount > 0 { parts.append("played \(game.playCount) times") }
        parts.append("weight \(settings.showWeightAs.render(game.weight))")
        return parts.joined(separator: ", ")
    }
}
