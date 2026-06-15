import SwiftUI
import SwiftData

/// The Wallet: searchable, sortable grid of loyalty cards with favorites pinned,
/// quick-add from the catalog, swipe-to-delete, and an empty state.
struct WalletScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var cards: [LoyaltyCard]

    @State private var search = ""
    @State private var showAdd = false
    @State private var showQuickAdd = false
    @State private var paywallReason: PaywallReason?
    @State private var categoryFilter: CardCategory?

    private let columns = [GridItem(.flexible(), spacing: 14),
                           GridItem(.flexible(), spacing: 14)]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if cards.isEmpty {
                    emptyState
                } else {
                    contentList
                }
            }
            .navigationTitle("Wallet")
            .toolbar { toolbarContent }
            .searchable(text: $search, prompt: "Search cards")
            .sheet(isPresented: $showAdd) {
                AddEditCardView(card: nil)
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddView { store in
                    addFromCatalog(store)
                }
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: Content

    private var contentList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if !isPro {
                    freeSlotsBanner
                }
                categoryChips

                if filtered.isEmpty {
                    EmptyStateView(symbol: "magnifyingglass",
                                   title: "No matches",
                                   message: "No cards match your search or filter. Try a different term.")
                        .padding(.top, 40)
                } else {
                    if !favorites.isEmpty {
                        SectionHeader(title: "Favorites", symbol: "star.fill")
                        grid(for: favorites)
                    }
                    if !others.isEmpty {
                        SectionHeader(title: favorites.isEmpty ? "All Cards" : "More", symbol: "wallet.pass")
                            .padding(.top, favorites.isEmpty ? 0 : 4)
                        grid(for: others)
                    }
                }
            }
            .padding(16)
        }
    }

    private func grid(for items: [LoyaltyCard]) -> some View {
        LazyVGrid(columns: columns, spacing: 14) {
            ForEach(items) { card in
                NavigationLink {
                    CardDetailView(card: card)
                } label: {
                    LoyaltyCardTile(card: card)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        toggleFavorite(card)
                    } label: {
                        Label(card.isFavorite ? "Unfavorite" : "Favorite",
                              systemImage: card.isFavorite ? "star.slash" : "star")
                    }
                    Button(role: .destructive) {
                        delete(card)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PillButton(title: "All", selected: categoryFilter == nil) {
                    categoryFilter = nil
                    Haptics.select(settings.hapticsEnabled)
                }
                ForEach(presentCategories) { category in
                    PillButton(title: category.displayName,
                               systemImage: category.symbol,
                               selected: categoryFilter == category) {
                        categoryFilter = (categoryFilter == category) ? nil : category
                        Haptics.select(settings.hapticsEnabled)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var freeSlotsBanner: some View {
        let remaining = Pro.remainingSlots(currentCount: cards.count, isPro: isPro) ?? 0
        return Button {
            paywallReason = .cardLimit
        } label: {
            HStack(spacing: 10) {
                Image(systemName: remaining == 0 ? "lock.fill" : "rectangle.stack")
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(remaining == 0 ? "Free wallet is full" : "\(remaining) free slot\(remaining == 1 ? "" : "s") left")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Stash Pro removes the \(Pro.freeCardLimit)-card limit.")
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.inkFaint)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.accentSoft))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        EmptyStateView(symbol: "wallet.pass",
                       title: "Your wallet is empty",
                       message: "Add your first loyalty card to pull up its barcode instantly at checkout.",
                       actionTitle: "Quick add a store") {
            showQuickAdd = true
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sort", selection: sortBinding) {
                    ForEach(CardSortOrder.allCases) { order in
                        Label(order.displayName, systemImage: order.symbol).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
            .accessibilityLabel("Sort cards")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    attemptAdd { showAdd = true }
                } label: {
                    Label("Custom card", systemImage: "square.and.pencil")
                }
                Button {
                    attemptAdd { showQuickAdd = true }
                } label: {
                    Label("Quick add from catalog", systemImage: "sparkles")
                }
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add card")
        }
    }

    private var sortBinding: Binding<CardSortOrder> {
        Binding(get: { settings.sortOrder },
                set: { settings.sortOrder = $0; Haptics.select(settings.hapticsEnabled) })
    }

    // MARK: Data shaping

    private var presentCategories: [CardCategory] {
        let present = Set(cards.map { $0.category })
        return CardCategory.allCases.filter { present.contains($0) }
    }

    private var filtered: [LoyaltyCard] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = cards
        if let categoryFilter {
            result = result.filter { $0.category == categoryFilter }
        }
        if !term.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(term)
                || $0.storeName.lowercased().contains(term)
                || $0.category.displayName.lowercased().contains(term)
            }
        }
        return sorted(result)
    }

    private func sorted(_ list: [LoyaltyCard]) -> [LoyaltyCard] {
        switch settings.sortOrder {
        case .name:
            return list.sorted { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        case .dateAdded:
            return list.sorted { $0.createdAt > $1.createdAt }
        case .category:
            return list.sorted {
                if $0.category.displayName == $1.category.displayName {
                    return $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending
                }
                return $0.category.displayName < $1.category.displayName
            }
        case .recentlyUsed:
            return list.sorted {
                let a = $0.lastUsedAt ?? $0.createdAt
                let b = $1.lastUsedAt ?? $1.createdAt
                return a > b
            }
        }
    }

    private var favorites: [LoyaltyCard] { filtered.filter { $0.isFavorite } }
    private var others: [LoyaltyCard] { filtered.filter { !$0.isFavorite } }

    // MARK: Actions

    private func attemptAdd(_ proceed: () -> Void) {
        if Pro.canAddCard(currentCount: cards.count, isPro: isPro) {
            proceed()
        } else {
            paywallReason = .cardLimit
        }
    }

    private func addFromCatalog(_ store: CatalogStore) {
        guard Pro.canAddCard(currentCount: cards.count, isPro: isPro) else {
            paywallReason = .cardLimit
            return
        }
        let card = LoyaltyCard(
            name: store.name,
            storeName: store.name,
            codeValue: "",
            format: store.suggestedFormat,
            category: store.category,
            colorHex: store.colorHex
        )
        context.insert(card)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    private func toggleFavorite(_ card: LoyaltyCard) {
        card.isFavorite.toggle()
        try? context.save()
        Haptics.select(settings.hapticsEnabled)
    }

    private func delete(_ card: LoyaltyCard) {
        context.delete(card)
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
