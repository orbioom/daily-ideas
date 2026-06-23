import SwiftUI
import SwiftData

/// Global browse & search across every phrase in every deck, with a favorites
/// filter and category filter.
struct BrowseView: View {
    @Query(sort: \Deck.sortIndex) private var decks: [Deck]
    @Query private var settingsList: [AppSettings]
    @Environment(\.modelContext) private var context

    @State private var query = ""
    @State private var favoritesOnly = false
    @State private var category: PhraseCategory? = nil

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    /// All phrases paired with their owning deck, filtered by the active query.
    private var results: [(deck: Deck, phrase: Phrase)] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var rows: [(Deck, Phrase)] = []
        for deck in decks {
            for phrase in deck.phrases.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                if favoritesOnly && !phrase.isFavorite { continue }
                if let category, phrase.category != category { continue }
                if !trimmed.isEmpty {
                    let hay = "\(phrase.source) \(phrase.target) \(phrase.pronunciation) \(deck.name)".lowercased()
                    if !hay.contains(trimmed) { continue }
                }
                rows.append((deck, phrase))
            }
        }
        return rows.map { (deck: $0.0, phrase: $0.1) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                content
            }
            .navigationTitle("Browse")
            .searchable(text: $query, prompt: "Search phrases or languages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        favoritesOnly.toggle()
                    } label: {
                        Image(systemName: favoritesOnly ? "heart.fill" : "heart")
                    }
                    .accessibilityLabel(favoritesOnly ? "Showing favorites only" : "Show favorites only")
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            categoryFilter
                .padding(.vertical, Theme.Spacing.sm)
            if results.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                List {
                    ForEach(results, id: \.phrase.id) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(row.deck.flag).accessibilityHidden(true)
                                Text(row.deck.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Theme.brand)
                            }
                            PhraseRow(
                                phrase: row.phrase,
                                localeIdentifier: row.deck.localeIdentifier,
                                showPronunciation: settings.showPronunciation,
                                speechRate: settings.speechRate,
                                hapticsEnabled: settings.hapticsEnabled,
                                onToggleFavorite: { toggleFavorite(row.phrase) }
                            )
                        }
                        .listRowBackground(Theme.card)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                FilterChip(title: "All", symbol: "square.grid.2x2", isOn: category == nil) {
                    category = nil
                }
                ForEach(PhraseCategory.allCases) { cat in
                    FilterChip(title: cat.title, symbol: cat.symbol, isOn: category == cat) {
                        category = (category == cat) ? nil : cat
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: favoritesOnly ? "heart.slash" : "magnifyingglass",
            title: favoritesOnly ? "No favorites yet" : "No matches",
            message: favoritesOnly
                ? "Tap the heart on any phrase to save it here for quick access on your trip."
                : "Try a different search term or category."
        )
    }

    private func toggleFavorite(_ phrase: Phrase) {
        phrase.isFavorite.toggle()
        try? context.save()
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        BrowseView().modelContainer(container)
    }
}
