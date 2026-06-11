import SwiftUI
import SwiftData

struct CustomDecksView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CustomDeck.createdAt) private var decks: [CustomDeck]
    @State private var editing: CustomDeck?
    @State private var creating = false

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    EmptyStateView(
                        icon: "rectangle.stack.badge.plus",
                        title: "Make your own deck",
                        message: "Inside jokes, coworkers' catchphrases, family lore — custom decks are where Romp gets dangerous. Add at least 5 cards to play one.",
                        actionTitle: "New deck"
                    ) { creating = true }
                } else {
                    List {
                        ForEach(decks) { deck in
                            Button {
                                editing = deck
                            } label: {
                                HStack(spacing: 12) {
                                    Text(deck.emoji)
                                        .font(.title2)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(deck.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(deck.words.count) card\(deck.words.count == 1 ? "" : "s")\(deck.words.count < 5 ? " — needs 5 to play" : "")")
                                            .font(.caption)
                                            .foregroundStyle(deck.words.count < 5 ? Theme.pass : Theme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .listRowBackground(Theme.bgElevated)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    context.delete(deck)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.bgPrimary)
            .navigationTitle("My decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { creating = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New custom deck")
                }
            }
            .sheet(item: $editing) { deck in
                CustomDeckEditorView(deck: deck)
            }
            .sheet(isPresented: $creating) {
                CustomDeckEditorView(deck: nil)
            }
        }
    }
}

struct CustomDeckEditorView: View {
    let deck: CustomDeck?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var emoji = "🎉"
    @State private var words: [String] = []
    @State private var newWord = ""
    @State private var validationMessage: String?
    @FocusState private var wordFieldFocused: Bool

    private let emojiChoices = ["🎉", "🤪", "🧠", "🏠", "💼", "🎓", "🎮", "🌍", "👨‍👩‍👧‍👦", "🐾"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck") {
                    TextField("Deck name", text: $name)
                    Picker("Icon", selection: $emoji) {
                        ForEach(emojiChoices, id: \.self) { e in
                            Text(e).tag(e)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    HStack {
                        TextField("Add a card…", text: $newWord)
                            .focused($wordFieldFocused)
                            .onSubmit(addWord)
                            .accessibilityLabel("New card text")
                        Button {
                            addWord()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityLabel("Add card")
                    }
                    if words.isEmpty {
                        Text("No cards yet — a deck needs at least 5 to play.")
                            .font(.caption)
                            .foregroundStyle(Theme.textSecondary)
                    } else {
                        ForEach(words.indices, id: \.self) { index in
                            Text(words[index])
                        }
                        .onDelete { offsets in
                            words.remove(atOffsets: offsets)
                        }
                    }
                } header: {
                    Text("Cards (\(words.count))")
                } footer: {
                    Text("Swipe a card to delete it. Duplicates are ignored.")
                }
            }
            .navigationTitle(deck == nil ? "New deck" : "Edit deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Can't save yet", isPresented: Binding(
                get: { validationMessage != nil },
                set: { if !$0 { validationMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage ?? "")
            }
            .onAppear {
                if let deck {
                    name = deck.name
                    emoji = deck.emoji
                    words = deck.words
                }
            }
        }
    }

    private func addWord() {
        let trimmed = newWord.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !words.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            words.append(trimmed)
            Haptics.tap()
        }
        newWord = ""
        wordFieldFocused = true
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            validationMessage = "Give the deck a name."
            return
        }
        if let deck {
            deck.name = trimmedName
            deck.emoji = emoji
            deck.words = words
        } else {
            context.insert(CustomDeck(name: trimmedName, emoji: emoji, words: words))
        }
        Haptics.correct()
        dismiss()
    }
}
