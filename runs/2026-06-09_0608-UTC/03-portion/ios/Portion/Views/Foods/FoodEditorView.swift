import SwiftUI
import SwiftData

/// Add or view/edit a food. Built-in foods are read-only; custom foods are
/// fully editable and deletable.
struct FoodEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = creating a new custom food; non-nil = viewing/editing an existing one.
    let food: FoodItem?

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var kcal: Double = 0
    @State private var protein: Double = 0
    @State private var carbs: Double = 0
    @State private var fat: Double = 0
    @State private var fiber: Double = 0
    @State private var gramsPerPiece: Double = 0
    @State private var gramsPerCup: Double = 0

    @State private var showDeleteConfirm = false
    @State private var loaded = false

    /// Built-in foods are presented read-only.
    private var isReadOnly: Bool { (food?.isCustom == false) }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            if isReadOnly {
                Section {
                    Text("Built-in foods can't be edited. Add a custom food to use your own values.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }
            }

            Section("Food") {
                TextField("Name", text: $name)
                    .disabled(isReadOnly)
                    .accessibilityLabel("Food name")
                Picker("Category", selection: $category) {
                    ForEach(FoodCategory.allCases) { c in
                        Label(c.label, systemImage: c.symbol).tag(c)
                    }
                }
                .disabled(isReadOnly)
            }

            Section("Per 100 g") {
                macroField("Calories", value: $kcal, unit: "kcal")
                macroField("Protein", value: $protein, unit: "g")
                macroField("Carbohydrate", value: $carbs, unit: "g")
                macroField("Fat", value: $fat, unit: "g")
                macroField("Fiber", value: $fiber, unit: "g")
            }

            Section {
                macroField("Grams per piece", value: $gramsPerPiece, unit: "g")
                macroField("Grams per cup", value: $gramsPerCup, unit: "g")
            } header: {
                Text("Household measures (optional)")
            } footer: {
                Text("Leave at 0 if not applicable. These enable piece and cup units when adding this food to a recipe.")
            }

            if let food, food.isCustom {
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete food", systemImage: "trash")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(food == nil ? "New Food" : (isReadOnly ? "Food" : "Edit Food"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isReadOnly {
                ToolbarItem(placement: .topBarLeading) {
                    if food == nil {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
        .confirmationDialog("Delete this food?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { deleteFood() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Recipes already using it keep their saved values.")
        }
        .onAppear(perform: loadIfNeeded)
    }

    @ViewBuilder
    private func macroField(_ label: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .disabled(isReadOnly)
                .accessibilityLabel("\(label) per 100 grams")
            Text(unit)
                .font(.footnote)
                .foregroundStyle(Brand.text3)
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let food else { return }
        name = food.name
        category = FoodCategory.from(food.category)
        kcal = food.kcalPer100
        protein = food.proteinPer100
        carbs = food.carbsPer100
        fat = food.fatPer100
        fiber = food.fiberPer100
        gramsPerPiece = food.gramsPerPiece
        gramsPerCup = food.gramsPerCup
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let food, food.isCustom {
            food.name = trimmed
            food.category = category.rawValue
            food.kcalPer100 = max(0, kcal)
            food.proteinPer100 = max(0, protein)
            food.carbsPer100 = max(0, carbs)
            food.fatPer100 = max(0, fat)
            food.fiberPer100 = max(0, fiber)
            food.gramsPerPiece = max(0, gramsPerPiece)
            food.gramsPerCup = max(0, gramsPerCup)
        } else if food == nil {
            let new = FoodItem(name: trimmed,
                               category: category.rawValue,
                               kcalPer100: kcal,
                               proteinPer100: protein,
                               carbsPer100: carbs,
                               fatPer100: fat,
                               fiberPer100: fiber,
                               gramsPerPiece: gramsPerPiece,
                               gramsPerCup: gramsPerCup,
                               isCustom: true)
            context.insert(new)
        }
        try? context.save()
        Haptics.success()
        dismiss()
    }

    private func deleteFood() {
        if let food, food.isCustom {
            context.delete(food)
            try? context.save()
            Haptics.warning()
            dismiss()
        }
    }
}
