import SwiftUI

/// Filter options for the library grid.
private enum LibraryFilter: Hashable {
    case all
    case major
    case suit(Suit)

    var title: String {
        switch self {
        case .all: return "All"
        case .major: return "Major"
        case .suit(let s): return s.title
        }
    }
}

struct LibraryView: View {
    @State private var search = ""
    @State private var filter: LibraryFilter = .all

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    private var filtered: [TarotCard] {
        var cards = TarotDeck.all
        switch filter {
        case .all: break
        case .major: cards = cards.filter { $0.arcana == .major }
        case .suit(let s): cards = cards.filter { $0.suit == s }
        }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            cards = cards.filter {
                $0.name.lowercased().contains(q)
                || $0.upright.contains { kw in kw.lowercased().contains(q) }
            }
        }
        return cards
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                filterChips

                if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass",
                                   title: "No cards found",
                                   message: "Try a different name, keyword, or filter.")
                } else {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(filtered) { card in
                            NavigationLink {
                                CardDetailView(card: card)
                            } label: {
                                CardFace(card: card, reversed: false, size: .compact)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Brand.pageBackground)
        .navigationTitle("Library")
        .searchable(text: $search, prompt: "Search 78 cards")
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(.all)
                chip(.major)
                ForEach(Suit.allCases) { suit in chip(.suit(suit)) }
            }
        }
    }

    private func chip(_ f: LibraryFilter) -> some View {
        SelectChip(text: f.title, isSelected: filter == f) {
            Haptics.selection()
            filter = f
        }
    }
}
