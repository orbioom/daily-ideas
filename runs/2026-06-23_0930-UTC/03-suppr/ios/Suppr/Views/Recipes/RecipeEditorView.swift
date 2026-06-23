import SwiftUI
import SwiftData

/// Create or edit a recipe with its ingredients and steps.
struct RecipeEditorView: View {
    /// nil = create a new recipe.
    let recipe: Recipe?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var summary = ""
    @State private var servings = 4
    @State private var prep = 10
    @State private var cook = 20
    @State private var effort: Effort = .easy
    @State private var tagsText = ""
    @State private var draftIngredients: [DraftIngredient] = []
    @State private var draftSteps: [DraftStep] = []
    @State private var showValidation = false

    struct DraftIngredient: Identifiable {
        let id = UUID()
        var name = ""
        var quantity = ""
        var unit = ""
        var aisle: Aisle = .other
        var isStaple = false
    }
    struct DraftStep: Identifiable {
        let id = UUID()
        var text = ""
    }

    private var isEditing: Bool { recipe != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool {
        !trimmedName.isEmpty &&
        draftIngredients.contains { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                effortSection
                ingredientsSection
                stepsSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    private var detailsSection: some View {
        Section("Details") {
            TextField("Recipe name", text: $name)
                .textInputAutocapitalization(.words)
            if showValidation && trimmedName.isEmpty {
                Label("A name is required.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Theme.terracotta)
            }
            TextField("Short summary (optional)", text: $summary, axis: .vertical)
                .lineLimit(1...3)
            TextField("Tags, comma separated", text: $tagsText)
                .textInputAutocapitalization(.words)
        }
    }

    private var effortSection: some View {
        Section("Servings & time") {
            Stepper(value: $servings, in: 1...20) {
                LabeledContent("Base servings", value: "\(servings)")
            }
            Stepper(value: $prep, in: 0...240, step: 5) {
                LabeledContent("Prep", value: "\(prep) min")
            }
            Stepper(value: $cook, in: 0...600, step: 5) {
                LabeledContent("Cook", value: "\(cook) min")
            }
            Picker("Effort", selection: $effort) {
                ForEach(Effort.allCases) { Text($0.rawValue).tag($0) }
            }
        }
    }

    private var ingredientsSection: some View {
        Section {
            if draftIngredients.isEmpty {
                Text("Add at least one ingredient.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
            ForEach($draftIngredients) { $ing in
                VStack(spacing: 8) {
                    TextField("Ingredient", text: $ing.name)
                    HStack {
                        TextField("Qty", text: $ing.quantity)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                        TextField("Unit", text: $ing.unit)
                            .frame(width: 80)
                        Spacer()
                        Picker("", selection: $ing.aisle) {
                            ForEach(Aisle.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .labelsHidden()
                    }
                    Toggle("Pantry staple", isOn: $ing.isStaple)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
            .onDelete { draftIngredients.remove(atOffsets: $0) }

            Button {
                draftIngredients.append(DraftIngredient())
                Haptics.tap()
            } label: {
                Label("Add ingredient", systemImage: "plus.circle")
            }
        } header: {
            Text("Ingredients")
        } footer: {
            Text("Quantities are for the base servings above. Suppr scales them on your plan.")
        }
    }

    private var stepsSection: some View {
        Section("Steps") {
            ForEach($draftSteps) { $step in
                TextField("Step", text: $step.text, axis: .vertical)
                    .lineLimit(1...4)
            }
            .onDelete { draftSteps.remove(atOffsets: $0) }
            Button {
                draftSteps.append(DraftStep())
                Haptics.tap()
            } label: {
                Label("Add step", systemImage: "plus.circle")
            }
        }
    }

    private func loadIfNeeded() {
        guard let recipe, draftIngredients.isEmpty, name.isEmpty else {
            if draftIngredients.isEmpty && recipe == nil {
                draftIngredients = [DraftIngredient()]
                draftSteps = [DraftStep()]
            }
            return
        }
        name = recipe.name
        summary = recipe.summary
        servings = recipe.servings
        prep = recipe.prepMinutes
        cook = recipe.cookMinutes
        effort = recipe.effort
        tagsText = recipe.tags.joined(separator: ", ")
        draftIngredients = recipe.sortedIngredients.map {
            DraftIngredient(
                name: $0.name,
                quantity: $0.quantity > 0 ? trimNumber($0.quantity) : "",
                unit: $0.unit,
                aisle: $0.aisle,
                isStaple: $0.isStaple
            )
        }
        if draftIngredients.isEmpty { draftIngredients = [DraftIngredient()] }
        draftSteps = recipe.steps.map { DraftStep(text: $0) }
        if draftSteps.isEmpty { draftSteps = [DraftStep()] }
    }

    private func trimNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(format: "%.2f", value)
    }

    private func save() {
        guard canSave else { showValidation = true; Haptics.warning(); return }

        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let steps = draftSteps
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let target: Recipe
        if let recipe {
            target = recipe
            // Replace ingredients wholesale.
            for old in recipe.ingredients { context.delete(old) }
            target.ingredients = []
        } else {
            target = Recipe(name: trimmedName)
            context.insert(target)
        }

        target.name = trimmedName
        target.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        target.servings = max(1, servings)
        target.prepMinutes = max(0, prep)
        target.cookMinutes = max(0, cook)
        target.effort = effort
        target.tags = tags
        target.steps = steps

        for draft in draftIngredients {
            let n = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !n.isEmpty else { continue }
            let qty = Double(draft.quantity.replacingOccurrences(of: ",", with: ".")) ?? 0
            let ing = Ingredient(
                name: n,
                quantity: max(0, qty),
                unit: draft.unit.trimmingCharacters(in: .whitespaces),
                aisle: draft.aisle,
                isStaple: draft.isStaple
            )
            ing.recipe = target
            context.insert(ing)
        }

        do {
            try context.save()
            Haptics.success()
            dismiss()
        } catch {
            context.rollback()
            showValidation = true
            Haptics.warning()
        }
    }
}
