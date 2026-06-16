import SwiftUI
import SwiftData

/// Add / edit a recipe: title, base servings, notes and an ordered ingredient list.
struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @Bindable var recipe: SavedRecipe

    // Draft fields for adding a new ingredient row.
    @State private var draftName = ""
    @State private var draftQty = ""
    @State private var draftUnit: MeasureUnit = .cup

    private var draftQuantity: Double? {
        Double(draftQty.trimmingCharacters(in: .whitespaces))
    }
    private var canAddDraft: Bool {
        !draftName.trimmingCharacters(in: .whitespaces).isEmpty && (draftQuantity ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Recipe title", text: $recipe.title)
                        .accessibilityLabel("Recipe title")
                    Stepper(value: $recipe.baseServings, in: 1...100) {
                        Text("Base servings: \(recipe.baseServings)")
                    }
                    .accessibilityValue("\(recipe.baseServings) servings")
                }

                Section("Ingredients") {
                    if recipe.ingredients.isEmpty {
                        Text("No ingredients yet. Add one below.")
                            .font(.subheadline)
                            .foregroundStyle(GalleyTheme.secondaryText(scheme))
                    }
                    ForEach(recipe.orderedIngredients) { ing in
                        HStack {
                            Text(FractionFormatter.string(ing.quantity))
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(GalleyTheme.terracotta)
                            Text(ing.unit.abbreviation)
                                .font(.caption)
                                .foregroundStyle(GalleyTheme.secondaryText(scheme))
                            Text(ing.name)
                                .foregroundStyle(GalleyTheme.primaryText(scheme))
                            Spacer()
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(FractionFormatter.string(ing.quantity)) \(ing.unit.fullName) \(ing.name)")
                    }
                    .onDelete(perform: deleteIngredients)
                }

                Section("Add ingredient") {
                    TextField("Quantity", text: $draftQty)
                        .keyboardType(.decimalPad)
                        .accessibilityLabel("Ingredient quantity")
                    Picker("Unit", selection: $draftUnit) {
                        Section("Volume") {
                            ForEach(MeasureUnit.volumeUnits) { Text($0.fullName).tag($0) }
                        }
                        Section("Weight") {
                            ForEach(MeasureUnit.weightUnits) { Text($0.fullName).tag($0) }
                        }
                    }
                    TextField("Ingredient name", text: $draftName)
                        .accessibilityLabel("Ingredient name")
                    Button {
                        addIngredient()
                    } label: {
                        Label("Add ingredient", systemImage: "plus.circle.fill")
                    }
                    .disabled(!canAddDraft)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $recipe.notes, axis: .vertical)
                        .lineLimit(2...5)
                        .accessibilityLabel("Recipe notes")
                }
            }
            .navigationTitle(recipe.title.isEmpty ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(recipe.title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func addIngredient() {
        guard canAddDraft, let qty = draftQuantity else { return }
        let order = (recipe.ingredients.map { $0.sortOrder }.max() ?? -1) + 1
        let ing = RecipeIngredient(
            name: draftName.trimmingCharacters(in: .whitespaces),
            quantity: qty,
            unit: draftUnit,
            sortOrder: order
        )
        // Append to the relationship; SwiftData maintains the inverse and
        // persists the child through the owning recipe.
        recipe.ingredients.append(ing)
        draftName = ""
        draftQty = ""
        Haptics.light()
    }

    private func deleteIngredients(at offsets: IndexSet) {
        let ordered = recipe.orderedIngredients
        for index in offsets {
            guard ordered.indices.contains(index) else { continue }
            let ing = ordered[index]
            if let pos = recipe.ingredients.firstIndex(where: { $0.id == ing.id }) {
                recipe.ingredients.remove(at: pos)
            }
            context.delete(ing)
        }
    }

    private func save() {
        if recipe.baseServings < 1 { recipe.baseServings = 1 }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        // If this is a brand-new, never-saved empty recipe, discard it.
        if recipe.title.trimmingCharacters(in: .whitespaces).isEmpty && recipe.ingredients.isEmpty {
            context.delete(recipe)
        }
        try? context.save()
        dismiss()
    }
}
