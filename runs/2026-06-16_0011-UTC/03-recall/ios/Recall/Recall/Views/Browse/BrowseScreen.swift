import SwiftUI
import SwiftData

/// Browse tab: pick a deck (including archived) to view and manage its cards.
struct BrowseScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Deck.createdDate, order: .reverse) private var allDecks: [Deck]

    @State private var showNewDeck = false
    @State private var paywallReason: PaywallReason?

    private var activeDecks: [Deck] { allDecks.filter { !$0.isArchived } }
    private var archivedDecks: [Deck] { allDecks.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Browse")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { attemptCreate() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New deck")
                }
            }
            .navigationDestination(for: Deck.self) { deck in
                DeckBrowseView(deck: deck)
            }
            .sheet(isPresented: $showNewDeck) { DeckEditorView(deck: nil) }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if allDecks.isEmpty {
            EmptyStateView(symbol: "magnifyingglass",
                           title: "Nothing to browse",
                           message: "Create a deck or load sample data, then browse, search, and edit every card here.",
                           actionTitle: "Create a deck") { attemptCreate() }
        } else {
            List {
                Section("Decks") {
                    ForEach(activeDecks) { deck in
                        NavigationLink(value: deck) { deckRow(deck) }
                    }
                }
                if !archivedDecks.isEmpty {
                    Section("Archived") {
                        ForEach(archivedDecks) { deck in
                            NavigationLink(value: deck) { deckRow(deck) }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
        }
    }

    private func deckRow(_ deck: Deck) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.deckGradient(seed: deck.colorSeed))
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: "rectangle.stack.fill").font(.system(size: 15)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(deck.cards.count) \(deck.cards.count == 1 ? "card" : "cards") · \(deck.category)")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func attemptCreate() {
        if isPro || activeDecks.count < Pro.freeDeckLimit {
            showNewDeck = true
        } else {
            paywallReason = .deckLimit
        }
    }
}

#Preview {
    BrowseScreen()
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
