import SwiftUI
import SwiftData

struct AddCharacterView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let story: FableStory

    @State private var name = ""
    @State private var role: CharacterRole = .hero
    @State private var description = ""
    @State private var traits = ""
    @State private var emoji = "⭐️"

    private let emojiOptions = ["⭐️","🦁","🐉","🧚","🧙","🦊","🐰","🐻","🦄","🦋","🐸","🦉","🐺","🐬","🌟","👸","🤴","🧜","🧝","🧞"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Character") {
                    TextField("Name", text: $name)
                        .accessibilityLabel("Character name")
                    Picker("Role", selection: $role) {
                        ForEach(CharacterRole.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .accessibilityLabel("Character role")
                }

                Section("Emoji") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button(action: { emoji = e }) {
                                    Text(e)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(emoji == e ? FableTheme.accent.opacity(0.2) : FableTheme.secondary))
                                        .overlay(Circle().stroke(emoji == e ? FableTheme.accent : Color.clear, lineWidth: 2))
                                }
                                .accessibilityLabel(e + (emoji == e ? ", selected" : ""))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                }

                Section("About") {
                    TextField("Description", text: $description)
                        .accessibilityLabel("Character description")
                    TextField("Personality traits", text: $traits)
                        .accessibilityLabel("Personality traits")
                }
            }
            .navigationTitle("Add Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let char = StoryCharacter(name: trimmed, role: role, story: story)
        char.description = description
        char.traits = traits
        char.emoji = emoji
        context.insert(char)
        try? context.save()
        dismiss()
    }
}
