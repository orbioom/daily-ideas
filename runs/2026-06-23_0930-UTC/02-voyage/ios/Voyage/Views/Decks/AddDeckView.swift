import SwiftUI
import SwiftData

/// Create a custom language deck. Lets the user pick a speech locale so
/// pronunciation works for their new language.
struct AddDeckView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Deck.sortIndex) private var decks: [Deck]

    @State private var name = ""
    @State private var endonym = ""
    @State private var flag = "🏳️"
    @State private var subtitle = ""
    @State private var locale = "en-US"

    /// A small curated set of common speech locales offered for new decks.
    private let locales: [(id: String, label: String)] = [
        ("en-US", "English (US)"),
        ("es-ES", "Spanish (Spain)"),
        ("es-MX", "Spanish (Mexico)"),
        ("fr-FR", "French"),
        ("it-IT", "Italian"),
        ("de-DE", "German"),
        ("pt-BR", "Portuguese (Brazil)"),
        ("ja-JP", "Japanese"),
        ("ko-KR", "Korean"),
        ("zh-CN", "Chinese (Mandarin)"),
        ("nl-NL", "Dutch"),
        ("sv-SE", "Swedish")
    ]

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    TextField("Name (e.g. German)", text: $name)
                        .accessibilityLabel("Deck name")
                    TextField("Endonym (e.g. Deutsch)", text: $endonym)
                        .accessibilityLabel("Native language name")
                    TextField("Flag emoji", text: $flag)
                        .accessibilityLabel("Flag emoji")
                }
                Section("Pronunciation voice") {
                    Picker("Voice", selection: $locale) {
                        ForEach(locales, id: \.id) { item in
                            Text(item.label).tag(item.id)
                        }
                    }
                }
                Section("Description") {
                    TextField("Short tagline (optional)", text: $subtitle, axis: .vertical)
                        .accessibilityLabel("Description")
                }
                Section {
                    Text("Your new deck starts empty. Add phrases from the deck screen, then study them with spaced repetition.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("New Deck")
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
        let nextIndex = (decks.map(\.sortIndex).max() ?? -1) + 1
        let cleanFlag = flag.trimmingCharacters(in: .whitespacesAndNewlines)
        let deck = Deck(
            name: trimmedName,
            endonym: endonym.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? trimmedName : endonym.trimmingCharacters(in: .whitespacesAndNewlines),
            flag: cleanFlag.isEmpty ? "🏳️" : cleanFlag,
            localeIdentifier: locale,
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom deck" : subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            sortIndex: nextIndex
        )
        context.insert(deck)
        try? context.save()
        dismiss()
    }
}

#Preview {
    if let container = PersistenceController.previewContainer() {
        AddDeckView().modelContainer(container)
    }
}
