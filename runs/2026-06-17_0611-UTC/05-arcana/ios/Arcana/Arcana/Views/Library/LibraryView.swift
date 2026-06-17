import SwiftUI

struct LibraryView: View {
    @State private var search = ""
    @State private var filter: LibraryFilter = .all

    private enum LibraryFilter: Hashable {
        case all, major
        case suit(Suit)

        var label: String {
            switch self {
            case .all: return "All"
            case .major: return "Major"
            case .suit(let s): return s.rawValue
            }
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 14)]

    private var filtered: [TarotCard] {
        var cards = Deck.all
        switch filter {
        case .all: break
        case .major: cards = cards.filter { $0.arcana == .major }
        case .suit(let s): cards = cards.filter { $0.suit == s }
        }
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            cards = cards.filter {
                $0.name.lowercased().contains(q) ||
                $0.keywords.contains { $0.lowercased().contains(q) }
            }
        }
        return cards
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    filterBar
                    if filtered.isEmpty {
                        EmptyStateView(icon: "magnifyingglass",
                                       title: "No cards match",
                                       message: "Try a different search or filter.")
                        Spacer()
                    } else {
                        ScrollView {
                            learnIntro
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filtered) { card in
                                    NavigationLink {
                                        CardDetailView(card: card)
                                    } label: {
                                        gridCell(card)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $search, prompt: "Search cards or keywords")
        }
    }

    private var learnIntro: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeading(title: "The Whole Deck", icon: "sparkles")
            Text("All 78 Rider–Waite–Smith cards — 22 Major Arcana and 56 Minor across Wands, Cups, Swords, and Pentacles. Tap any card for its full upright and reversed meaning. The complete deck is free, forever.")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(.all)
                chip(.major)
                ForEach(Suit.allCases) { chip(.suit($0)) }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ f: LibraryFilter) -> some View {
        let selected = f == filter
        return Button {
            filter = f
        } label: {
            Text(f.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selected ? .white : Theme.inkSoft)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(selected ? Theme.accent : Theme.surfaceAlt))
        }
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private func gridCell(_ card: TarotCard) -> some View {
        VStack(spacing: 6) {
            CardArtView(card: card, showName: false)
            Text(card.name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 30)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(card.name)
        .accessibilityHint("Opens the card's full meaning")
    }
}
