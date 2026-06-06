import SwiftUI
import SwiftData

struct RecipeEditView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Ingredient.name) private var ingredients: [Ingredient]
    @AppStorage("defaultMeasure") private var defaultMeasureRaw = Measure.oz.rawValue
    let recipe: Recipe?

    private var defaultMeasure: Measure { Measure(rawValue: defaultMeasureRaw) ?? .oz }

    @State private var name = ""
    @State private var method = Method.shaken
    @State private var glass = "Coupe"
    @State private var instructions = ""
    @State private var notes = ""
    @State private var drafts: [Draft] = []
    @State private var showNewIngredient = false
    @State private var newIngredientName = ""
    @State private var newIngredientCategory = IngredientCategory.spirit

    private let glasses = ["Coupe", "Rocks", "Highball", "Collins", "Martini", "Wine", "Nick & Nora", "Mug", "Flute"]
    private var valid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && drafts.contains { $0.ingredient != nil && !$0.optional }
    }

    struct Draft: Identifiable {
        let id = UUID()
        var ingredient: Ingredient?
        var amount: Double
        var measure: Measure
        var optional: Bool
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cocktail") {
                    TextField("Name", text: $name)
                    Picker("Method", selection: $method) {
                        ForEach(Method.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Glass", selection: $glass) {
                        ForEach(glasses, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section {
                    ForEach($drafts) { $d in
                        VStack(spacing: 8) {
                            HStack {
                                Menu {
                                    ForEach(ingredients) { ing in
                                        Button(ing.name) { $d.ingredient.wrappedValue = ing }
                                    }
                                    Divider()
                                    Button { showNewIngredient = true } label: {
                                        Label("New ingredient…", systemImage: "plus")
                                    }
                                } label: {
                                    HStack {
                                        Text(d.ingredient?.name ?? "Choose ingredient")
                                            .foregroundStyle(d.ingredient == nil ? Brand.text3 : Brand.text)
                                        Image(systemName: "chevron.up.chevron.down").font(.caption2)
                                            .foregroundStyle(Brand.text3)
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    drafts.removeAll { $0.id == d.id }
                                } label: { Image(systemName: "minus.circle.fill").foregroundStyle(Brand.danger) }
                                .accessibilityLabel("Remove line")
                            }
                            HStack(spacing: 8) {
                                TextField("0", value: $d.amount, format: .number)
                                    .keyboardType(.decimalPad).font(Brand.mono(15))
                                    .frame(width: 56)
                                    .textFieldStyle(.roundedBorder)
                                Picker("", selection: $d.measure) {
                                    ForEach(Measure.allCases) { Text($0.rawValue).tag($0) }
                                }
                                .labelsHidden()
                                Spacer()
                                Toggle("Optional", isOn: $d.optional).labelsHidden()
                                Text("opt").font(.caption).foregroundStyle(Brand.text3)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    Button {
                        drafts.append(Draft(ingredient: nil, amount: 1, measure: defaultMeasure, optional: false))
                    } label: { Label("Add ingredient line", systemImage: "plus") }
                } header: { Text("Ingredients") } footer: {
                    Text("Mark garnishes and \"to taste\" lines as optional — they won't block makeability.")
                }
                Section("Method") {
                    TextField("Instructions", text: $instructions, axis: .vertical).lineLimit(2...6)
                }
                Section("Notes") {
                    TextField("Origin, variations…", text: $notes, axis: .vertical).lineLimit(1...4)
                }
            }
            .scrollContentBackground(.hidden).background(Brand.pageBackground)
            .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid) }
            }
            .onAppear(perform: load)
            .alert("New ingredient", isPresented: $showNewIngredient) {
                TextField("Name", text: $newIngredientName)
                Button("Add") { addIngredient() }
                Button("Cancel", role: .cancel) { newIngredientName = "" }
            } message: { Text("Adds it to your bar (out of stock). You can change category in the Bar tab.") }
        }
    }

    private func load() {
        if let r = recipe {
            name = r.name; method = r.method; glass = r.glass
            instructions = r.instructions; notes = r.notes
            drafts = r.components.map { Draft(ingredient: $0.ingredient, amount: $0.amount,
                                              measure: $0.measure, optional: $0.optional) }
        } else {
            drafts = [Draft(ingredient: nil, amount: 2, measure: defaultMeasure, optional: false)]
        }
    }

    private func addIngredient() {
        let trimmed = newIngredientName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let ing = Ingredient(name: trimmed, category: newIngredientCategory, inStock: false)
        context.insert(ing)
        if let idx = drafts.firstIndex(where: { $0.ingredient == nil }) {
            drafts[idx].ingredient = ing
        } else {
            drafts.append(Draft(ingredient: ing, amount: 1, measure: .oz, optional: false))
        }
        newIngredientName = ""
        Haptics.success()
    }

    private func save() {
        let target: Recipe
        if let r = recipe {
            target = r
            target.name = name; target.method = method; target.glass = glass
            target.instructions = instructions; target.notes = notes
            for c in target.components { context.delete(c) }
            target.components.removeAll()
        } else {
            target = Recipe(name: name, method: method, glass: glass,
                            instructions: instructions, notes: notes)
            context.insert(target)
        }
        for d in drafts where d.ingredient != nil {
            let c = RecipeComponent(amount: max(0, d.amount), measure: d.measure,
                                    optional: d.optional, ingredient: d.ingredient)
            c.recipe = target
            context.insert(c)
            target.components.append(c)
        }
        try? context.save(); Haptics.success(); dismiss()
    }
}
