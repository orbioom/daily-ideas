import SwiftUI
import SwiftData

/// Add or edit a single card (front/back required, hint/example optional).
/// When editing, also shows live SRS state and a reset action.
struct CardEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    let deck: Deck
    /// nil = adding new.
    let card: Card?

    @State private var front = ""
    @State private var back = ""
    @State private var hint = ""
    @State private var example = ""
    @State private var isSuspended = false
    @State private var validationMessage: String?

    private var isEditing: Bool { card != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card") {
                    TextField("Front (question)", text: $front, axis: .vertical)
                        .lineLimit(1...3)
                    TextField("Back (answer)", text: $back, axis: .vertical)
                        .lineLimit(1...3)
                }
                Section("Optional") {
                    TextField("Hint", text: $hint)
                    TextField("Example sentence", text: $example, axis: .vertical)
                        .lineLimit(1...3)
                } footer: {
                    Text("For Type mode, separate accepted answers with a slash, e.g. \"color / colour\".")
                }

                if isEditing {
                    Section("Status") {
                        Toggle(isOn: $isSuspended) {
                            Label("Suspended", systemImage: "pause.circle")
                        }
                    }
                    if let card { srsSection(card) }
                    Section {
                        Button(role: .destructive) { deleteCard() } label: {
                            Label("Delete card", systemImage: "trash")
                        }
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
            .navigationTitle(isEditing ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func srsSection(_ card: Card) -> some View {
        Section("Schedule") {
            row("Maturity", value: card.maturity.rawValue)
            row("Interval", value: card.isNew ? "—" : SRSEngine.formatInterval(days: card.intervalDays))
            row("Ease", value: String(format: "%.2f", card.ease))
            row("Reviews", value: "\(card.repetitions)")
            row("Lapses", value: "\(card.lapses)")
            if let last = card.lastReviewed {
                row("Last seen", value: last.formatted(date: .abbreviated, time: .omitted))
            }
            Button { resetCard(card) } label: {
                Label("Reset progress", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.ink)
            Spacer()
            Text(value).foregroundStyle(Theme.inkSoft).monospacedDigit()
        }
        .font(Theme.rounded(15))
    }

    private func load() {
        if let card {
            front = card.front
            back = card.back
            hint = card.hint
            example = card.example
            isSuspended = card.isSuspended
        }
    }

    private func save() {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else {
            validationMessage = "Both the front and back are required."
            Haptics.error(enabled: settings.hapticsEnabled)
            return
        }
        if let card {
            card.front = f
            card.back = b
            card.hint = hint.trimmingCharacters(in: .whitespacesAndNewlines)
            card.example = example.trimmingCharacters(in: .whitespacesAndNewlines)
            card.isSuspended = isSuspended
        } else {
            let newCard = Card(front: f,
                               back: b,
                               hint: hint.trimmingCharacters(in: .whitespacesAndNewlines),
                               example: example.trimmingCharacters(in: .whitespacesAndNewlines),
                               dueDate: Date())
            newCard.deck = deck
            deck.cards.append(newCard)
        }
        try? context.save()
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func deleteCard() {
        if let card {
            context.delete(card)
            try? context.save()
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    private func resetCard(_ card: Card) {
        card.ease = 2.5
        card.intervalDays = 0
        card.repetitions = 0
        card.lapses = 0
        card.lastReviewed = nil
        card.dueDate = Date()
        try? context.save()
        Haptics.tap(enabled: settings.hapticsEnabled)
    }
}

#Preview {
    if let deck = PreviewContainer.firstDeck() {
        CardEditorView(deck: deck, card: nil)
            .environmentObject(AppSettings())
            .modelContainer(PreviewContainer.shared)
    } else {
        Text("No deck")
    }
}
