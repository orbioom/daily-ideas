import SwiftUI
import SwiftData

/// Sheet for adding a custom phrase to a deck. Validates required fields.
struct AddPhraseView: View {
    let deck: Deck
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var source = ""
    @State private var target = ""
    @State private var pronunciation = ""
    @State private var category: PhraseCategory = .basics
    @State private var showSuccess = false

    private var trimmedSource: String { source.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedTarget: String { target.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool {
        !trimmedSource.isEmpty && !trimmedTarget.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Meaning (English)") {
                    TextField("e.g. Where is the bus stop?", text: $source, axis: .vertical)
                        .accessibilityLabel("English meaning")
                }
                Section("\(deck.name) translation") {
                    TextField("Translation", text: $target, axis: .vertical)
                        .accessibilityLabel("Translation")
                    TextField("Pronunciation (optional)", text: $pronunciation)
                        .accessibilityLabel("Pronunciation hint")
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(PhraseCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.symbol).tag(cat)
                        }
                    }
                }
                if showSuccess {
                    Section {
                        Label("Phrase added", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Theme.success)
                    }
                }
            }
            .navigationTitle("New Phrase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        guard canSave else { return }
        let maxOrder = deck.phrases.map(\.orderIndex).max() ?? -1
        let phrase = Phrase(
            source: trimmedSource,
            target: trimmedTarget,
            pronunciation: pronunciation.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            orderIndex: maxOrder + 1,
            deck: deck
        )
        context.insert(phrase)
        try? context.save()
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
    }
}

#Preview {
    if let container = PersistenceController.previewContainer(),
       let deck = (try? container.mainContext.fetch(FetchDescriptor<Deck>()))?.first {
        AddPhraseView(deck: deck).modelContainer(container)
    }
}
