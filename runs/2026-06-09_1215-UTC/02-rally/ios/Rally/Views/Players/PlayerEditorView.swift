import SwiftUI
import SwiftData

/// Add or edit a player. Editing "You" keeps the `isMe` flag; new players are
/// always opponents/partners. Rating is editable for new players (a starting
/// estimate) but read-only once matches have evolved it.
struct PlayerEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// Existing player to edit, or `nil` to create a new one.
    var player: Player? = nil

    @State private var name = ""
    @State private var note = ""
    @State private var rating = 3.0
    @State private var showError = false

    private var isEditing: Bool { player != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Player name", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Starting rating") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Rating").foregroundStyle(Brand.text)
                            Spacer()
                            Text(Format.rating(rating))
                                .font(Brand.mono(16, weight: .semibold))
                                .foregroundStyle(Brand.magic)
                        }
                        Slider(value: $rating, in: 2.0...6.0, step: 0.05)
                            .accessibilityLabel("Starting rating")
                            .accessibilityValue(Format.rating(rating))
                    }
                } footer: {
                    Text("A 2.0–6.0 DUPR-style estimate. It updates automatically after every match.")
                }
                Section("Note (optional)") {
                    TextField("e.g. Big serve, lefty", text: $note, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(isEditing ? "Edit Player" : "Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
            .alert("Name required", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a name for this player.")
            }
        }
    }

    private func load() {
        guard let player else { return }
        name = player.name
        note = player.note
        rating = player.rating
    }

    private func save() {
        guard canSave else { Haptics.warning(); showError = true; return }
        if let player {
            player.name = trimmedName
            player.note = note
            player.rating = Player.clampRating(rating)
        } else {
            let new = Player(name: trimmedName, rating: rating, note: note)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
