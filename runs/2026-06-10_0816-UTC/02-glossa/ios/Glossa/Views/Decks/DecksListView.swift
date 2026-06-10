import SwiftUI
import SwiftData

struct DecksListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.createdAt) private var decks: [Deck]
    @State private var showNewDeck = false
    @State private var deleteTarget: Deck?

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if decks.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack",
                        title: "No decks yet",
                        message: "Add a language pack or start a custom deck — every word you study lives on this device."
                    )
                } else {
                    List {
                        ForEach(decks) { deck in
                            NavigationLink(value: deck) {
                                DeckRow(deck: deck)
                            }
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteTarget = deck
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Decks")
            .navigationDestination(for: Deck.self) { DeckDetailView(deck: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewDeck = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add deck")
                }
            }
            .sheet(isPresented: $showNewDeck) { NewDeckView() }
            .alert("Delete this deck?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let d = deleteTarget {
                        context.delete(d)
                        Haptics.warning()
                    }
                    deleteTarget = nil
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("All cards and their progress in this deck are removed.")
            }
        }
    }
}

private struct DeckRow: View {
    let deck: Deck

    var body: some View {
        HStack(spacing: 12) {
            Text(deck.flag)
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text("\(deck.cards.count) cards · \(deck.masteredCount) mastered")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
            let due = deck.dueCards().count
            if due > 0 {
                Text("\(due) due")
                    .font(Brand.mono(12, weight: .semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Brand.live.opacity(0.18), in: Capsule())
                    .foregroundStyle(Brand.live)
                    .accessibilityLabel("\(due) cards due")
            }
        }
        .padding(.vertical, 4)
    }
}

/// Sheet: install a built-in pack as a new deck, or start a custom deck.
struct NewDeckView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var customName = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Language packs") {
                    ForEach(Lexicon.packs) { pack in
                        Button {
                            let deck = Deck(name: "\(pack.name) essentials", languageCode: pack.code)
                            context.insert(deck)
                            deck.cards = pack.entries.map { entry in
                                Card(front: entry.front, back: entry.back, gender: entry.gender,
                                     exampleTarget: entry.exampleTarget, exampleEnglish: entry.exampleEnglish,
                                     catalogID: entry.id)
                            }
                            Haptics.success()
                            dismiss()
                        } label: {
                            HStack {
                                Text(pack.flag).accessibilityHidden(true)
                                Text(pack.name).foregroundStyle(Brand.text)
                                Spacer()
                                Text("\(pack.entries.count) words")
                                    .font(Brand.mono(13))
                                    .foregroundStyle(Brand.text3)
                            }
                        }
                        .accessibilityLabel("Install \(pack.name) pack, \(pack.entries.count) words")
                    }
                }
                Section("Custom deck") {
                    TextField("Deck name (e.g. Italian food words)", text: $customName)
                    Button("Create empty deck") {
                        let trimmed = customName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            error = "Give the deck a name first."
                            return
                        }
                        context.insert(Deck(name: trimmed, languageCode: "custom"))
                        Haptics.success()
                        dismiss()
                    }
                    if let error {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
