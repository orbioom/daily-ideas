import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]

    @State private var showingCreateDeck = false

    var body: some View {
        NavigationStack {
            ZStack {
                SleeveTheme.darkBg.ignoresSafeArea()

                if decks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 56))
                            .foregroundStyle(SleeveTheme.subtleText)
                        Text("No Decks Yet")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Text("Tap New Deck to build your first")
                            .font(.subheadline)
                            .foregroundStyle(SleeveTheme.subtleText)
                    }
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckDetailView(deck: deck)) {
                                DeckRow(deck: deck)
                            }
                            .listRowBackground(SleeveTheme.cardBg)
                        }
                        .onDelete(perform: deleteDecks)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateDeck = true
                    } label: {
                        Label("New Deck", systemImage: "plus")
                            .foregroundStyle(SleeveTheme.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateDeck) {
            CreateDeckView()
        }
        .preferredColorScheme(.dark)
    }

    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(decks[index])
        }
    }
}

struct DeckRow: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(SleeveTheme.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(SleeveTheme.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(deck.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(deck.game)
                    .font(.caption)
                    .foregroundStyle(SleeveTheme.subtleText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(deck.cardCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("cards")
                    .font(.caption2)
                    .foregroundStyle(SleeveTheme.subtleText)
            }

            // Format badge
            Text(deck.format)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(SleeveTheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(SleeveTheme.accent.opacity(0.15))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeckListView()
}
