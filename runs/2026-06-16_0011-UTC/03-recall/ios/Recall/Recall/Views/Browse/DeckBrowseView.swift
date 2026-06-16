import SwiftUI
import SwiftData

/// Searchable card list for one deck. Add/edit/delete cards, suspend/reset, edit the deck.
struct DeckBrowseView: View {
    @Bindable var deck: Deck

    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @State private var search = ""
    @State private var editingCard: Card?
    @State private var showNewCard = false
    @State private var showDeckEditor = false
    @State private var maturityFilter: Maturity?

    private var filteredCards: [Card] {
        let base = deck.cards.sorted { $0.createdDate < $1.createdDate }
        let byMaturity = maturityFilter.map { m in base.filter { $0.maturity == m } } ?? base
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return byMaturity }
        return byMaturity.filter {
            $0.front.localizedCaseInsensitiveContains(q) ||
            $0.back.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            content
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Search cards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showNewCard = true } label: { Label("Add card", systemImage: "plus") }
                    Button { showDeckEditor = true } label: { Label("Edit deck", systemImage: "slider.horizontal.3") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Deck actions")
            }
        }
        .sheet(isPresented: $showNewCard) { CardEditorView(deck: deck, card: nil) }
        .sheet(item: $editingCard) { CardEditorView(deck: deck, card: $0) }
        .sheet(isPresented: $showDeckEditor) { DeckEditorView(deck: deck) }
    }

    @ViewBuilder
    private var content: some View {
        if deck.cards.isEmpty {
            EmptyStateView(symbol: "rectangle.badge.plus",
                           title: "No cards yet",
                           message: "Add your first card to \(deck.name) and it'll be ready to study.",
                           actionTitle: "Add a card") { showNewCard = true }
        } else {
            List {
                Section {
                    filterChips
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                }
                Section {
                    if filteredCards.isEmpty {
                        Text("No cards match your search.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(filteredCards) { card in
                            cardRow(card)
                        }
                    }
                } header: {
                    Text("\(filteredCards.count) \(filteredCards.count == 1 ? "card" : "cards")")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", active: maturityFilter == nil) { maturityFilter = nil }
                ForEach(Maturity.allCases) { m in
                    chip(title: m.rawValue, active: maturityFilter == m, color: m.color) {
                        maturityFilter = (maturityFilter == m) ? nil : m
                    }
                }
            }
        }
    }

    private func chip(title: String, active: Bool, color: Color = Theme.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(13, .semibold))
                .foregroundStyle(active ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(active ? color : color.opacity(0.14)))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    private func cardRow(_ card: Card) -> some View {
        Button { editingCard = card } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.front)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(card.back)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .lineLimit(1)
                }
                Spacer()
                if card.isSuspended {
                    Image(systemName: "pause.circle.fill")
                        .foregroundStyle(Theme.inkFaint)
                        .accessibilityLabel("Suspended")
                } else {
                    MaturityChip(maturity: card.maturity)
                }
            }
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) { delete(card) } label: {
                Label("Delete", systemImage: "trash")
            }
            Button { toggleSuspend(card) } label: {
                Label(card.isSuspended ? "Resume" : "Suspend",
                      systemImage: card.isSuspended ? "play.fill" : "pause.fill")
            }
            .tint(Theme.warn)
        }
        .swipeActions(edge: .leading) {
            Button { reset(card) } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .tint(Theme.accent)
        }
    }

    // MARK: Actions

    private func delete(_ card: Card) {
        context.delete(card)
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
    }

    private func toggleSuspend(_ card: Card) {
        card.isSuspended.toggle()
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func reset(_ card: Card) {
        card.ease = 2.5
        card.intervalDays = 0
        card.repetitions = 0
        card.lapses = 0
        card.lastReviewed = nil
        card.dueDate = Date()
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    NavigationStack {
        if let deck = PreviewContainer.firstDeck() {
            DeckBrowseView(deck: deck)
        } else {
            Text("No deck")
        }
    }
    .environmentObject(AppSettings())
    .modelContainer(PreviewContainer.shared)
}
