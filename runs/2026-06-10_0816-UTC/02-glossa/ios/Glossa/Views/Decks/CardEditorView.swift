import SwiftUI
import SwiftData

/// Add (card == nil) or edit a card. Deleting is offered while editing.
struct CardEditorView: View {
    let deck: Deck
    let card: Card?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var front = ""
    @State private var back = ""
    @State private var gender = ""
    @State private var exampleTarget = ""
    @State private var exampleEnglish = ""
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Word") {
                    TextField("Target word (e.g. la casa)", text: $front)
                        .autocorrectionDisabled()
                    TextField("Meaning (e.g. the house)", text: $back)
                    Picker("Gender", selection: $gender) {
                        Text("None").tag("")
                        Text("Masculine").tag("m")
                        Text("Feminine").tag("f")
                        Text("Neuter").tag("n")
                    }
                }
                Section("Example (optional)") {
                    TextField("Example sentence", text: $exampleTarget, axis: .vertical)
                    TextField("Example translation", text: $exampleEnglish, axis: .vertical)
                }
                if let card {
                    Section("Progress") {
                        LabeledContent("Box", value: "\(card.box) of \(LeitnerEngine.boxCount)")
                        LabeledContent("Reviews", value: "\(card.reviews)")
                        LabeledContent("Lapses", value: "\(card.lapses)")
                        LabeledContent("Next review", value: card.dueDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    Section {
                        Button("Delete card", role: .destructive) { confirmDelete = true }
                    }
                }
                if let error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundStyle(Brand.danger)
                    }
                }
            }
            .navigationTitle(card == nil ? "New Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Delete this card?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let card {
                        context.delete(card)
                        Haptics.warning()
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let card {
                    front = card.front
                    back = card.back
                    gender = card.gender
                    exampleTarget = card.exampleTarget
                    exampleEnglish = card.exampleEnglish
                }
            }
        }
    }

    private func save() {
        let f = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = back.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !f.isEmpty, !b.isEmpty else {
            error = "Both the word and its meaning are required."
            return
        }
        if let card {
            card.front = f
            card.back = b
            card.gender = gender
            card.exampleTarget = exampleTarget.trimmingCharacters(in: .whitespacesAndNewlines)
            card.exampleEnglish = exampleEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let new = Card(front: f, back: b, gender: gender,
                           exampleTarget: exampleTarget.trimmingCharacters(in: .whitespacesAndNewlines),
                           exampleEnglish: exampleEnglish.trimmingCharacters(in: .whitespacesAndNewlines))
            context.insert(new)
            new.deck = deck
        }
        Haptics.success()
        dismiss()
    }
}
