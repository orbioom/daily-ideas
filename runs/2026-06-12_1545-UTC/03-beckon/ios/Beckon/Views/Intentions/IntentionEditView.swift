import SwiftUI
import SwiftData

struct IntentionEditView: View {
    let intention: Intention?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var affirmation = ""
    @State private var category: IntentionCategory = .growth
    @State private var practiceLength = 33

    private var isEditing: Bool { intention != nil }
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !affirmation.trimmingCharacters(in: .whitespaces).isEmpty
    }
    private var suggestions: [String] { AffirmationLibrary.suggestions(for: category) }

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you calling in?") {
                    TextField("Short title (e.g. Dream role)", text: $title)
                    Picker("Category", selection: $category) {
                        ForEach(IntentionCategory.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
                    }
                }
                Section {
                    TextField("I am… (present tense)", text: $affirmation, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Your affirmation")
                } footer: {
                    Text("Write it as if it's already true — present tense, positive, and personal.")
                }
                if !suggestions.isEmpty {
                    Section("Need inspiration?") {
                        ForEach(suggestions, id: \.self) { s in
                            Button {
                                Haptics.tap(); affirmation = s
                            } label: {
                                Text(s).font(.subheadline).foregroundStyle(Theme.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                Section("Practice cycle") {
                    Picker("Length", selection: $practiceLength) {
                        Text("33 days").tag(33)
                        Text("45 days").tag(45)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(isEditing ? "Edit Intention" : "New Intention")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let i = intention else { return }
        title = i.title; affirmation = i.affirmation
        category = i.category; practiceLength = i.practiceLength
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = affirmation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, !a.isEmpty else { return }
        if let i = intention {
            i.title = t; i.affirmation = a; i.category = category; i.practiceLength = practiceLength
        } else {
            let i = Intention(title: t, affirmation: a, category: category, practiceLength: practiceLength)
            context.insert(i)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
