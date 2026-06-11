import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    let deck: FlashDeck
    let card: FlashCard?

    @State private var front: String
    @State private var back: String
    @State private var cardType: CardType

    init(deck: FlashDeck, card: FlashCard?) {
        self.deck = deck
        self.card = card
        _front    = State(initialValue: card?.front ?? "")
        _back     = State(initialValue: card?.back  ?? "")
        _cardType = State(initialValue: card.map { CardType(rawValue: $0.cardTypeRaw) ?? .basic } ?? .basic)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Type") {
                    Picker("Type", selection: $cardType) {
                        ForEach(CardType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Card type")
                }

                if cardType == .cloze {
                    Section {
                        Text("Use {{word}} to mark the hidden part.\nExample: The capital of France is {{Paris}}.")
                            .font(.caption)
                            .foregroundStyle(DeckTheme.subtle)
                    }
                }

                Section(cardType == .cloze ? "Text (with cloze marks)" : "Front") {
                    TextEditor(text: $front)
                        .frame(minHeight: 80)
                        .accessibilityLabel(cardType == .cloze ? "Card text with cloze marks" : "Card front")
                }

                if cardType == .basic {
                    Section("Back") {
                        TextEditor(text: $back)
                            .frame(minHeight: 80)
                            .accessibilityLabel("Card back")
                    }
                }

                if cardType == .cloze && !front.isEmpty {
                    Section("Preview") {
                        let preview = FlashCard(front: front, back: "", cardType: .cloze)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Question:")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DeckTheme.subtle)
                            Text(preview.clozeDisplayFront)
                                .foregroundStyle(DeckTheme.text)
                            Text("Answer:")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DeckTheme.subtle)
                            Text(preview.clozeAnswer.isEmpty ? "—" : preview.clozeAnswer)
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DeckTheme.bg)
            .navigationTitle(card == nil ? "New Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(front.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmedFront = front.trimmingCharacters(in: .whitespaces)
        guard !trimmedFront.isEmpty else { return }
        if let existing = card {
            existing.front = trimmedFront
            existing.back = back.trimmingCharacters(in: .whitespaces)
            existing.cardTypeRaw = cardType.rawValue
        } else {
            let newCard = FlashCard(
                front: trimmedFront,
                back: back.trimmingCharacters(in: .whitespaces),
                cardType: cardType
            )
            newCard.deck = deck
            ctx.insert(newCard)
        }
        dismiss()
    }
}
