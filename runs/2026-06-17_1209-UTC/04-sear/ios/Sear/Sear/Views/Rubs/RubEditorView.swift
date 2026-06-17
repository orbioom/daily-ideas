import SwiftUI
import SwiftData

/// Create a new rub or edit an existing one. Ingredients are edited as a line list.
struct RubEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    /// The rub being edited, or nil to create a new one.
    let rub: Rub?

    @State private var name: String
    @State private var ingredients: [String]
    @State private var steps: String
    @State private var notes: String

    init(rub: Rub?) {
        self.rub = rub
        _name = State(initialValue: rub?.name ?? "")
        let seedIngredients = rub?.ingredients ?? []
        _ingredients = State(initialValue: seedIngredients.isEmpty ? [""] : seedIngredients)
        _steps = State(initialValue: rub?.steps ?? "")
        _notes = State(initialValue: rub?.notes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && cleanedIngredients.isEmpty == false
    }

    private var cleanedIngredients: [String] {
        ingredients
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. My Brisket Rub", text: $name)
                }
                Section("Ingredients") {
                    ForEach(ingredients.indices, id: \.self) { idx in
                        TextField("e.g. Paprika — 2 tbsp", text: binding(for: idx))
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                        if ingredients.isEmpty { ingredients = [""] }
                    }
                    Button {
                        ingredients.append("")
                    } label: {
                        Label("Add ingredient", systemImage: "plus")
                    }
                }
                Section("Method (optional)") {
                    TextField("How to mix and apply", text: $steps, axis: .vertical)
                        .lineLimit(2...6)
                }
                Section("Notes (optional)") {
                    TextField("Pairings, tweaks…", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(rub == nil ? "New Rub" : "Edit Rub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { ingredients[safe: index] ?? "" },
            set: { newValue in
                if ingredients.indices.contains(index) { ingredients[index] = newValue }
            }
        )
    }

    private func save() {
        guard canSave else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let finalSteps = steps.trimmingCharacters(in: .whitespaces)
        let finalNotes = notes.trimmingCharacters(in: .whitespaces)

        if let rub {
            rub.name = trimmedName
            rub.ingredients = cleanedIngredients
            rub.steps = finalSteps.isEmpty ? nil : finalSteps
            rub.notes = finalNotes
        } else {
            let newRub = Rub(name: trimmedName,
                             ingredients: cleanedIngredients,
                             steps: finalSteps.isEmpty ? nil : finalSteps,
                             notes: finalNotes,
                             isBuiltInCopy: true)
            context.insert(newRub)
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
