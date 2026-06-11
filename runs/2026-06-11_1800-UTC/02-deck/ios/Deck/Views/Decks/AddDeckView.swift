import SwiftUI
import SwiftData

struct AddDeckView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColorHex = "#4F8EF7"
    @State private var selectedEmoji = "📚"
    @State private var description = ""

    private let emojis = ["📚","🧠","💡","📖","🔬","🌍","🎯","✏️","💻","🏆","🔑","🎵","🌱","⭐️","🎭"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Name") {
                    TextField("e.g. Spanish Vocabulary", text: $name)
                        .accessibilityLabel("Deck name")
                    TextField("Description (optional)", text: $description)
                        .accessibilityLabel("Deck description")
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(selectedEmoji == emoji ? DeckTheme.accent.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .onTapGesture { selectedEmoji = emoji }
                                .accessibilityLabel("Icon: \(emoji)")
                                .accessibilityAddTraits(selectedEmoji == emoji ? [.isSelected] : [])
                        }
                    }
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 8), spacing: 12) {
                        ForEach(DeckTheme.deckColors, id: \.hex) { item in
                            Circle()
                                .fill(DeckTheme.colorFromHex(item.hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(.white, lineWidth: selectedColorHex == item.hex ? 3 : 0)
                                        .padding(3)
                                )
                                .shadow(color: DeckTheme.colorFromHex(item.hex).opacity(0.4), radius: 4)
                                .onTapGesture { selectedColorHex = item.hex }
                                .accessibilityLabel("\(item.name) color")
                                .accessibilityAddTraits(selectedColorHex == item.hex ? [.isSelected] : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DeckTheme.bg)
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let deck = FlashDeck(name: trimmed, colorHex: selectedColorHex, emoji: selectedEmoji, description: description)
        ctx.insert(deck)
        dismiss()
    }
}
