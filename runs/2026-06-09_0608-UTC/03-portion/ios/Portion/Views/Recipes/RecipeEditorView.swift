import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = creating a new recipe; non-nil = editing an existing one.
    let recipe: Recipe?

    @State private var name = ""
    @State private var servings = 1
    @State private var notes = ""
    @State private var draftIngredients: [DraftIngredient] = []

    @State private var showFoodPicker = false
    @State private var showDeleteConfirm = false
    @State private var loaded = false

    /// A working copy of an ingredient so edits aren't committed until Save.
    private struct DraftIngredient: Identifiable {
        let id = UUID()
        var foodName: String
        var displayQuantity: Double
        var unit: MeasureUnit
        var kcalPer100: Double
        var proteinPer100: Double
        var carbsPer100: Double
        var fatPer100: Double
        var fiberPer100: Double
        /// Snapshot of household measures so unit conversion still works in the
        /// editor even after the source food is gone.
        var gramsPerPiece: Double
        var gramsPerCup: Double

        var grams: Double {
            switch unit {
            case .gram: return max(0, displayQuantity)
            case .ounce: return max(0, displayQuantity) * MeasureUnit.gramsPerOunce
            case .tablespoon: return max(0, displayQuantity) * MeasureUnit.gramsPerTablespoon
            case .piece: return gramsPerPiece > 0 ? max(0, displayQuantity) * gramsPerPiece : max(0, displayQuantity)
            case .cup: return gramsPerCup > 0 ? max(0, displayQuantity) * gramsPerCup : max(0, displayQuantity)
            }
        }

        var kcal: Double {
            kcalPer100 * grams / 100.0
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var totalKcal: Double {
        draftIngredients.reduce(0) { $0 + $1.kcal }
    }

    var body: some View {
        Form {
            Section("Recipe") {
                TextField("Name", text: $name)
                    .accessibilityLabel("Recipe name")
                Stepper(value: $servings, in: 1...100) {
                    HStack {
                        Text("Servings")
                        Spacer()
                        Text("\(servings)")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                }
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(1...4)
            }

            Section {
                if draftIngredients.isEmpty {
                    Text("No ingredients yet. Add foods from the catalog to compute nutrition.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach($draftIngredients) { $draft in
                        ingredientRow($draft)
                    }
                    .onMove { from, to in
                        draftIngredients.move(fromOffsets: from, toOffset: to)
                    }
                    .onDelete { offsets in
                        draftIngredients.remove(atOffsets: offsets)
                        Haptics.tap()
                    }
                }
                Button {
                    Haptics.tap()
                    showFoodPicker = true
                } label: {
                    Label("Add ingredient", systemImage: "plus.circle")
                }
            } header: {
                HStack {
                    Text("Ingredients")
                    Spacer()
                    if !draftIngredients.isEmpty {
                        Text("\(Format.kcal(totalKcal)) kcal total")
                            .font(Brand.mono(11, weight: .medium))
                            .foregroundStyle(Brand.text3)
                            .textCase(nil)
                    }
                }
            }

            if recipe != nil {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete recipe", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
            }
            ToolbarItem(placement: .principal) { EditButton() }
        }
        .sheet(isPresented: $showFoodPicker) {
            NavigationStack {
                FoodPickerView { food, quantity, unit in
                    addIngredient(food: food, quantity: quantity, unit: unit)
                }
            }
        }
        .confirmationDialog("Delete this recipe?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteRecipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes the recipe and its ingredients.")
        }
        .onAppear(perform: loadIfNeeded)
    }

    // MARK: - Ingredient row

    @ViewBuilder
    private func ingredientRow(_ draft: Binding<DraftIngredient>) -> some View {
        let d = draft.wrappedValue
        let units = availableUnits(for: d)
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(d.foodName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
                Text("\(Format.kcal(d.kcal)) kcal")
                    .font(Brand.mono(12, weight: .semibold))
                    .foregroundStyle(Brand.text2)
            }
            HStack(spacing: 10) {
                TextField("Qty", value: draft.displayQuantity, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .accessibilityLabel("Quantity for \(d.foodName)")
                Picker("Unit", selection: draft.unit) {
                    ForEach(units) { u in Text(u.longLabel).tag(u) }
                }
                .labelsHidden()
                Spacer()
                Text(Format.grams(d.grams))
                    .font(Brand.mono(12))
                    .foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 4)
    }

    private func availableUnits(for d: DraftIngredient) -> [MeasureUnit] {
        var units: [MeasureUnit] = [.gram, .ounce, .tablespoon]
        if d.gramsPerPiece > 0 { units.append(.piece) }
        if d.gramsPerCup > 0 { units.append(.cup) }
        // Keep the currently-selected unit available even if its household
        // measure isn't known (e.g. re-editing a saved ingredient).
        if !units.contains(d.unit) { units.append(d.unit) }
        return units
    }

    // MARK: - Actions

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let recipe else { return }
        name = recipe.name
        servings = recipe.safeServings
        notes = recipe.notes
        draftIngredients = recipe.orderedIngredients.map { ing in
            // RecipeIngredient stores canonical grams + display qty/unit but not
            // the food's household measures. Reconstruct grams-per-unit from the
            // snapshot so piece/cup ingredients keep their exact grams on re-edit.
            let perUnit = ing.displayQuantity > 0 ? ing.grams / ing.displayQuantity : 0
            return DraftIngredient(foodName: ing.foodName,
                                   displayQuantity: ing.displayQuantity,
                                   unit: ing.unit,
                                   kcalPer100: ing.kcalPer100,
                                   proteinPer100: ing.proteinPer100,
                                   carbsPer100: ing.carbsPer100,
                                   fatPer100: ing.fatPer100,
                                   fiberPer100: ing.fiberPer100,
                                   gramsPerPiece: ing.unit == .piece ? perUnit : 0,
                                   gramsPerCup: ing.unit == .cup ? perUnit : 0)
        }
    }

    private func addIngredient(food: FoodItem, quantity: Double, unit: MeasureUnit) {
        let draft = DraftIngredient(foodName: food.name,
                                    displayQuantity: quantity,
                                    unit: unit,
                                    kcalPer100: food.kcalPer100,
                                    proteinPer100: food.proteinPer100,
                                    carbsPer100: food.carbsPer100,
                                    fatPer100: food.fatPer100,
                                    fiberPer100: food.fiberPer100,
                                    gramsPerPiece: food.gramsPerPiece,
                                    gramsPerCup: food.gramsPerCup)
        withAnimation(Brand.ease()) { draftIngredients.append(draft) }
        Haptics.tap()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let target: Recipe
        if let recipe {
            target = recipe
            // Replace ingredients wholesale (clears old, rebuilds in order).
            for old in recipe.ingredients { context.delete(old) }
            recipe.ingredients.removeAll()
        } else {
            target = Recipe(name: trimmed, servings: servings, notes: notes)
            context.insert(target)
        }
        target.name = trimmed
        target.servings = min(max(servings, 1), 100)
        target.notes = notes

        for (i, d) in draftIngredients.enumerated() {
            let ing = RecipeIngredient(foodName: d.foodName,
                                       grams: d.grams,
                                       displayQuantity: d.displayQuantity,
                                       unit: d.unit,
                                       kcalPer100: d.kcalPer100,
                                       proteinPer100: d.proteinPer100,
                                       carbsPer100: d.carbsPer100,
                                       fatPer100: d.fatPer100,
                                       fiberPer100: d.fiberPer100,
                                       order: i)
            ing.recipe = target
            context.insert(ing)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteRecipe() {
        if let recipe {
            context.delete(recipe)
            try? context.save()
            Haptics.warning()
        }
        dismiss()
    }
}
