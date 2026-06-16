import SwiftUI
import SwiftData

/// Create or edit a deck: name, description, category, color seed, archive/delete.
struct DeckEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// nil = creating a new deck.
    let deck: Deck?

    @State private var name = ""
    @State private var deckDescription = ""
    @State private var category = "General"
    @State private var colorSeed = 0
    @State private var isArchived = false
    @State private var validationMessage: String?
    @State private var showDeleteConfirm = false

    private let categories = ["General", "Languages", "Science", "Geography",
                              "Test Prep", "History", "Math", "Medicine", "Other"]
    private let seedCount = 8

    private var isEditing: Bool { deck != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck") {
                    TextField("Deck name", text: $name)
                    TextField("Description (optional)", text: $deckDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }

                Section("Color") {
                    colorPicker
                }

                if isEditing {
                    Section {
                        Toggle(isOn: $isArchived) {
                            Label("Archived", systemImage: "archivebox")
                        }
                    } footer: {
                        Text("Archived decks are hidden from the Decks list and study-all.")
                    }
                    Section {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete deck", systemImage: "trash")
                        }
                    } footer: {
                        Text("Deletes the deck and all its cards and review history.")
                    }
                }

                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.bad)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Deck" : "New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .confirmationDialog("Delete this deck?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Delete deck", role: .destructive) { deleteDeck() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes the deck, its cards, and history.")
            }
            .onAppear(perform: load)
        }
    }

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48), spacing: 12)], spacing: 12) {
            ForEach(0..<seedCount, id: \.self) { seed in
                Button {
                    colorSeed = seed
                    Haptics.selection(enabled: settings.hapticsEnabled)
                } label: {
                    Circle()
                        .fill(Theme.deckGradient(seed: seed))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle().strokeBorder(Theme.ink, lineWidth: colorSeed == seed ? 3 : 0)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(colorSeed == seed ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Color \(seed + 1)")
                .accessibilityAddTraits(colorSeed == seed ? .isSelected : [])
            }
        }
        .padding(.vertical, 4)
    }

    private func load() {
        if let deck {
            name = deck.name
            deckDescription = deck.deckDescription
            category = deck.category
            colorSeed = deck.colorSeed
            isArchived = deck.isArchived
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationMessage = "Give the deck a name."
            Haptics.error(enabled: settings.hapticsEnabled)
            return
        }
        if let deck {
            deck.name = trimmed
            deck.deckDescription = deckDescription
            deck.category = category
            deck.colorSeed = colorSeed
            deck.isArchived = isArchived
        } else {
            let newDeck = Deck(name: trimmed,
                               deckDescription: deckDescription,
                               colorSeed: colorSeed,
                               category: category)
            context.insert(newDeck)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteDeck() {
        if let deck {
            context.delete(deck)
            try? context.save()
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }
}

#Preview {
    DeckEditorView(deck: nil)
        .environmentObject(AppSettings())
        .modelContainer(PreviewContainer.shared)
}
