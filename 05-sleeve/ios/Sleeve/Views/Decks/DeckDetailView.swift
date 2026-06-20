import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let deck: Deck

    @State private var showingAddCard = false
    @State private var showingQuantitySheet = false
    @State private var selectedEntry: DeckEntry? = nil
    @State private var newQuantity = 1

    var body: some View {
        ZStack {
            SleeveTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Deck header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deck.game)
                            .font(.caption)
                            .foregroundStyle(SleeveTheme.subtleText)
                        Text("\(deck.cardCount) cards")
                            .font(.subheadline)
                            .foregroundStyle(SleeveTheme.silver)
                    }
                    Spacer()
                    Text(deck.format)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(SleeveTheme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(SleeveTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(SleeveTheme.cardBg)

                if deck.entries.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundStyle(SleeveTheme.subtleText)
                        Text("No cards in this deck")
                            .font(.subheadline)
                            .foregroundStyle(SleeveTheme.subtleText)
                        Button("Add Cards") {
                            showingAddCard = true
                        }
                        .buttonStyle(.bordered)
                        .tint(SleeveTheme.accent)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(deck.entries) { entry in
                            DeckEntryRow(entry: entry)
                                .listRowBackground(SleeveTheme.cardBg)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        modelContext.delete(entry)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        selectedEntry = entry
                                        newQuantity = entry.quantity
                                        showingQuantitySheet = true
                                    } label: {
                                        Label("Qty", systemImage: "number")
                                    }
                                    .tint(SleeveTheme.accent)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(SleeveTheme.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardToDeckView(deck: deck)
        }
        .sheet(isPresented: $showingQuantitySheet) {
            if let entry = selectedEntry {
                QuantityEditView(entry: entry, quantity: $newQuantity)
            }
        }
    }
}

struct DeckEntryRow: View {
    let entry: DeckEntry

    var body: some View {
        HStack {
            Text(entry.cardName)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            Text("x\(entry.quantity)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(SleeveTheme.silver)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Card to Deck

struct AddCardToDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck

    @Query(sort: \Card.name) private var allCards: [Card]
    @State private var searchText = ""
    @State private var quantity = 1

    var filteredCards: [Card] {
        if searchText.isEmpty { return allCards.filter { $0.game == deck.game } }
        return allCards.filter {
            $0.game == deck.game &&
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(SleeveTheme.subtleText)
                        TextField("Search collection...", text: $searchText)
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(SleeveTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if filteredCards.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("No \(deck.game) cards in collection")
                                .foregroundStyle(SleeveTheme.subtleText)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredCards) { card in
                                Button {
                                    addCard(card)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(card.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.white)
                                            Text(card.setName)
                                                .font(.caption)
                                                .foregroundStyle(SleeveTheme.subtleText)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(SleeveTheme.accent)
                                    }
                                }
                                .listRowBackground(SleeveTheme.cardBg)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Add to \(deck.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(SleeveTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func addCard(_ card: Card) {
        // Check if card already in deck
        if let existing = deck.entries.first(where: { $0.cardId == card.persistentModelID }) {
            existing.quantity += 1
        } else {
            let entry = DeckEntry(card: card, quantity: 1)
            entry.deck = deck
            modelContext.insert(entry)
        }
    }
}

// MARK: - Quantity Edit

struct QuantityEditView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: DeckEntry
    @Binding var quantity: Int

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 24) {
                    Text(entry.cardName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                        .foregroundStyle(.white)
                        .padding()
                        .background(SleeveTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
            }
            .navigationTitle("Edit Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(SleeveTheme.silver)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        entry.quantity = quantity
                        dismiss()
                    }
                    .foregroundStyle(SleeveTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(220)])
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck(name: "Charizard Ex Deck", game: CardGame.pokemon.rawValue, format: "Standard"))
    }
}
