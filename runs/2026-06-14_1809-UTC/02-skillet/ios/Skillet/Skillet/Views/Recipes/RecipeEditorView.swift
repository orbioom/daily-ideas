import SwiftUI
import SwiftData

/// Sheet editor for creating or editing a custom recipe, with validation.
struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    /// When set, edits this recipe in place; otherwise creates a new custom one.
    var existing: Recipe?

    @State private var name = ""
    @State private var cuisine: Cuisine = .other
    @State private var minutes = 30
    @State private var servings = 2
    @State private var difficulty: Difficulty = .easy
    @State private var notes = ""
    @State private var ingredientDrafts: [IngredientDraft] = []
    @State private var stepsText = ""
    @State private var validationMessage: String?
    @State private var loaded = false

    private struct IngredientDraft: Identifiable {
        let id = UUID()
        var name: String = ""
        var amount: String = ""
        var optional: Bool = false
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var validIngredients: [IngredientDraft] {
        ingredientDrafts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    private var stepLines: [String] {
        stepsText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    private var canSave: Bool {
        !trimmedName.isEmpty && !validIngredients.isEmpty && !stepLines.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage {
                    Section {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.bad)
                    }
                }

                Section("Recipe") {
                    TextField("Name", text: $name)
                    Picker(selection: $cuisine) {
                        ForEach(Cuisine.allCases) { c in
                            Label(c.rawValue, systemImage: c.symbol).tag(c)
                        }
                    } label: { Label("Cuisine", systemImage: "globe") }
                    Picker(selection: $difficulty) {
                        ForEach(Difficulty.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    } label: { Label("Difficulty", systemImage: "gauge.with.dots.needle.50percent") }
                    Stepper(value: $minutes, in: 5...300, step: 5) {
                        Label("\(minutes) min", systemImage: "clock")
                    }
                    Stepper(value: $servings, in: 1...24) {
                        Label("\(servings) servings", systemImage: "person.2")
                    }
                }

                Section {
                    ForEach($ingredientDrafts) { $draft in
                        VStack(spacing: 6) {
                            TextField("Ingredient", text: $draft.name)
                            HStack {
                                TextField("Amount (e.g. 2 cups)", text: $draft.amount)
                                Toggle("Optional", isOn: $draft.optional)
                                    .labelsHidden()
                                Text("Opt.")
                                    .font(Theme.rounded(11))
                                    .foregroundStyle(Theme.inkFaint)
                            }
                        }
                    }
                    .onDelete { ingredientDrafts.remove(atOffsets: $0) }
                    Button {
                        ingredientDrafts.append(IngredientDraft())
                    } label: {
                        Label("Add ingredient", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    Text("At least one ingredient is required.")
                }

                Section {
                    TextField("One step per line", text: $stepsText, axis: .vertical)
                        .lineLimit(4...12)
                } header: {
                    Text("Steps")
                } footer: {
                    Text("Put each step on its own line. At least one step is required.")
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(existing == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let existing {
            name = existing.name
            cuisine = existing.cuisine
            minutes = max(5, existing.minutes)
            servings = max(1, existing.servings)
            difficulty = existing.difficulty
            notes = existing.notes
            stepsText = existing.steps.joined(separator: "\n")
            ingredientDrafts = existing.ingredients.map {
                IngredientDraft(name: $0.name, amount: $0.amount, optional: $0.optional)
            }
        }
        if ingredientDrafts.isEmpty {
            ingredientDrafts = [IngredientDraft(), IngredientDraft()]
        }
        if existing == nil {
            servings = settings.clampedServings(settings.defaultServings)
        }
    }

    private func save() {
        guard canSave else {
            validationMessage = "Add a name, at least one ingredient, and at least one step."
            Haptics.warning(settings.hapticsEnabled)
            return
        }

        if let existing {
            existing.name = trimmedName
            existing.cuisine = cuisine
            existing.minutes = minutes
            existing.servings = servings
            existing.difficulty = difficulty
            existing.notes = notes.trimmingCharacters(in: .whitespaces)
            existing.steps = stepLines
            // Replace ingredients (cascade removes the old ones).
            for ing in existing.ingredients { context.delete(ing) }
            existing.ingredients = []
            for draft in validIngredients {
                let ing = RecipeIngredient(name: draft.name.trimmingCharacters(in: .whitespaces),
                                           amount: draft.amount.trimmingCharacters(in: .whitespaces),
                                           optional: draft.optional)
                ing.recipe = existing
                existing.ingredients.append(ing)
            }
        } else {
            let recipe = Recipe(name: trimmedName,
                                cuisine: cuisine,
                                minutes: minutes,
                                servings: servings,
                                difficulty: difficulty,
                                steps: stepLines,
                                notes: notes.trimmingCharacters(in: .whitespaces),
                                isCustom: true)
            context.insert(recipe)
            for draft in validIngredients {
                let ing = RecipeIngredient(name: draft.name.trimmingCharacters(in: .whitespaces),
                                           amount: draft.amount.trimmingCharacters(in: .whitespaces),
                                           optional: draft.optional)
                ing.recipe = recipe
                recipe.ingredients.append(ing)
            }
        }

        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        dismiss()
    }
}
