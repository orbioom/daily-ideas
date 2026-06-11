import SwiftUI
import SwiftData

struct DecksView: View {
    @Query(sort: \FlashDeck.createdAt, order: .reverse) private var decks: [FlashDeck]
    @Environment(\.modelContext) private var ctx
    @State private var showAdd = false

    var totalDue: Int { decks.reduce(0) { $0 + $1.dueCount } }

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyState
                } else {
                    List {
                        if totalDue > 0 {
                            Section {
                                DueAllRow(count: totalDue, decks: decks)
                            }
                        }
                        Section("Your Decks") {
                            ForEach(decks) { deck in
                                NavigationLink(value: deck) {
                                    DeckRowView(deck: deck)
                                }
                            }
                            .onDelete(perform: deleteDecks)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(DeckTheme.bg)
                }
            }
            .navigationTitle("Deck")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("New deck")
                    }
                }
            }
            .navigationDestination(for: FlashDeck.self) { deck in
                DeckDetailView(deck: deck)
            }
            .sheet(isPresented: $showAdd) {
                AddDeckView()
            }
        }
    }

    private func deleteDecks(at offsets: IndexSet) {
        for idx in offsets { ctx.delete(decks[idx]) }
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 64))
                .foregroundStyle(DeckTheme.accent.opacity(0.4))
                .accessibilityHidden(true)

            Text("No decks yet")
                .font(.title3.weight(.bold))
                .foregroundStyle(DeckTheme.text)

            Text("Create your first deck to start studying with spaced repetition.")
                .font(.body)
                .foregroundStyle(DeckTheme.subtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Create Deck") { showAdd = true }
                .buttonStyle(.borderedProminent)
                .tint(DeckTheme.accent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DeckTheme.bg)
    }
}

private struct DueAllRow: View {
    let count: Int
    let decks: [FlashDeck]

    var body: some View {
        NavigationLink(destination: AllDueStudyView(decks: decks)) {
            HStack {
                ZStack {
                    Circle()
                        .fill(DeckTheme.accent.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text("⚡️")
                        .font(.title2)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Study All Due")
                        .font(.headline)
                        .foregroundStyle(DeckTheme.text)
                    Text("\(count) cards due across all decks")
                        .font(.caption)
                        .foregroundStyle(DeckTheme.subtle)
                }
                Spacer()
                Text("\(count)")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(DeckTheme.accent, in: Capsule())
            }
            .padding(.vertical, 4)
        }
    }
}

struct DeckRowView: View {
    let deck: FlashDeck

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(DeckTheme.colorFromHex(deck.colorHex).opacity(0.2))
                    .frame(width: 48, height: 48)
                Text(deck.emoji)
                    .font(.title2)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(DeckTheme.text)
                HStack(spacing: 8) {
                    Text("\(deck.cards.count) cards")
                        .font(.caption)
                        .foregroundStyle(DeckTheme.subtle)
                    if deck.dueCount > 0 {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(DeckTheme.subtle)
                        Text("\(deck.dueCount) due")
                            .font(.caption)
                            .foregroundStyle(DeckTheme.colorFromHex(deck.colorHex))
                    }
                }
            }

            Spacer()

            if deck.dueCount > 0 {
                Text("\(deck.dueCount)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(DeckTheme.colorFromHex(deck.colorHex), in: Capsule())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(deck.name), \(deck.cards.count) cards, \(deck.dueCount) due")
    }
}
