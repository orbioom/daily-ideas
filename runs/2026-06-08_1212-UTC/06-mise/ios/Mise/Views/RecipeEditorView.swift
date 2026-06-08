import SwiftUI
import SwiftData

struct RecipeEditorView: View {
    @Bindable var recipe: Recipe
    let isNew: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    private let palette: [UInt32] = [0xB0673E, 0x3E9E78, 0xC0953E, 0x6E7BA6, 0x9E5E7E, 0x4E9EA6, 0xC0553E, 0x5C5A3E]

    private var sortedIngredients: [Ingredient] { recipe.ingredients.sorted { $0.order < $1.order } }
    private var sortedSteps: [Step] { recipe.steps.sorted { $0.order < $1.order } }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Recipe") {
                        TextField("Name", text: $recipe.name)
                        TextField("Short summary", text: $recipe.summary, axis: .vertical).lineLimit(1...3)
                        Picker("Course", selection: Binding(get: { recipe.course }, set: { recipe.course = $0 })) {
                            ForEach(RecipeCourse.allCases) { c in Label(c.label, systemImage: c.symbol).tag(c) }
                        }
                        Toggle("Favorite", isOn: $recipe.favorite).tint(Color(hex: 0xC0553E))
                    }

                    Section("Details") {
                        Stepper("Servings: \(recipe.servings)", value: $recipe.servings, in: 1...50)
                        Stepper("Prep: \(recipe.prepMinutes) min", value: $recipe.prepMinutes, in: 0...600, step: 5)
                        Stepper("Cook: \(recipe.cookMinutes) min", value: $recipe.cookMinutes, in: 0...600, step: 5)
                    }

                    Section("Ingredients") {
                        ForEach(sortedIngredients) { ing in
                            ingredientEditor(ing)
                        }
                        .onDelete { idx in
                            for i in idx { context.delete(sortedIngredients[i]) }
                        }
                        Button {
                            let order = (recipe.ingredients.map { $0.order }.max() ?? -1) + 1
                            let ing = Ingredient(name: "", order: order, recipe: recipe)
                            context.insert(ing)
                        } label: { Label("Add ingredient", systemImage: "plus.circle") }
                    }

                    Section("Method") {
                        ForEach(Array(sortedSteps.enumerated()), id: \.element.id) { idx, step in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(idx + 1).").font(Brand.mono(13, weight: .bold)).foregroundStyle(Color.accentColor)
                                    .padding(.top, 8)
                                TextField("Step", text: bindingForStep(step), axis: .vertical).lineLimit(1...5)
                            }
                        }
                        .onDelete { idx in
                            for i in idx { context.delete(sortedSteps[i]) }
                        }
                        Button {
                            let order = (recipe.steps.map { $0.order }.max() ?? -1) + 1
                            context.insert(Step(text: "", order: order, recipe: recipe))
                        } label: { Label("Add step", systemImage: "plus.circle") }
                    }

                    Section("Notes") {
                        TextField("Notes", text: $recipe.notes, axis: .vertical).lineLimit(2...6)
                    }

                    Section("Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(palette, id: \.self) { hex in
                                Circle().fill(Color(hex: hex)).frame(width: 28, height: 28)
                                    .overlay(Circle().strokeBorder(.white, lineWidth: recipe.colorHex == hex ? 3 : 0))
                                    .overlay(Circle().strokeBorder(Brand.hairline, lineWidth: 1))
                                    .onTapGesture { recipe.colorHex = hex; Haptics.selection() }
                            }
                        }
                    }

                    if !isNew {
                        Section {
                            Button(role: .destructive) {
                                context.delete(recipe); Haptics.warning(); dismiss()
                            } label: {
                                Label("Delete recipe", systemImage: "trash").frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isNew ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        if isNew && recipe.name.trimmingCharacters(in: .whitespaces).isEmpty { context.delete(recipe) }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }.fontWeight(.semibold)
                        .disabled(recipe.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func ingredientEditor(_ ing: Ingredient) -> some View {
        VStack(spacing: 6) {
            TextField("Ingredient name", text: bindingForName(ing))
            HStack(spacing: 8) {
                TextField("Qty", value: bindingForQty(ing), format: .number)
                    .keyboardType(.decimalPad).frame(width: 60)
                Picker("", selection: bindingForUnit(ing)) {
                    ForEach(Unit.allCases) { u in Text(u.label).tag(u) }
                }
                .labelsHidden()
                Picker("", selection: bindingForAisle(ing)) {
                    ForEach(Aisle.allCases) { a in Text(a.label).tag(a) }
                }
                .labelsHidden()
            }
        }
    }

    // MARK: - Bindings into related objects

    private func bindingForName(_ ing: Ingredient) -> Binding<String> {
        Binding(get: { ing.name }, set: { ing.name = $0 })
    }
    private func bindingForQty(_ ing: Ingredient) -> Binding<Double> {
        Binding(get: { ing.quantity }, set: { ing.quantity = max(0, $0) })
    }
    private func bindingForUnit(_ ing: Ingredient) -> Binding<Unit> {
        Binding(get: { ing.unit }, set: { ing.unit = $0 })
    }
    private func bindingForAisle(_ ing: Ingredient) -> Binding<Aisle> {
        Binding(get: { ing.aisle }, set: { ing.aisle = $0 })
    }
    private func bindingForStep(_ step: Step) -> Binding<String> {
        Binding(get: { step.text }, set: { step.text = $0 })
    }

    private func save() {
        // Drop empty ingredients/steps so they don't clutter the recipe.
        for ing in recipe.ingredients where ing.name.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(ing)
        }
        for step in recipe.steps where step.text.trimmingCharacters(in: .whitespaces).isEmpty {
            context.delete(step)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }
}
