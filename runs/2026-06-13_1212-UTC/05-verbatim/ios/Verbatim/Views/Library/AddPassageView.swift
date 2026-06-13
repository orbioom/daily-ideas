import SwiftUI
import SwiftData

/// Add or edit a passage: title, source, category, and the full text with a
/// live word count.
struct AddPassageView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var model: AddPassageViewModel

    init(editing: Passage? = nil) {
        let startRaw = UserDefaults.standard.string(forKey: "startingCategory") ?? PassageCategory.poem.rawValue
        let start = PassageCategory(rawValue: startRaw) ?? .poem
        _model = State(initialValue: AddPassageViewModel(editing: editing, startingCategory: start))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                Form {
                    Section("Details") {
                        TextField("Title", text: $model.title)
                            .font(Theme.rounded(16, .regular))
                        TextField("Source or author (optional)", text: $model.source)
                            .font(Theme.rounded(16, .regular))
                        Picker("Category", selection: $model.category) {
                            ForEach(PassageCategory.allCases) { c in
                                Label(c.displayName, systemImage: c.icon).tag(c)
                            }
                        }
                    }

                    Section {
                        TextEditor(text: $model.fullText)
                            .font(Theme.serif(17, .regular))
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                    } header: {
                        Text("Passage")
                    } footer: {
                        Text("\(model.liveWordCount) words · line breaks and stanza spacing are preserved exactly.")
                            .font(Theme.rounded(12, .regular))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(model.isEditing ? "Edit passage" : "New passage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if model.save(context: context) { dismiss() }
                    }
                    .disabled(!model.canSave)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
