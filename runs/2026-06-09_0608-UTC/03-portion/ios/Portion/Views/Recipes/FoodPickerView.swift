import SwiftUI
import SwiftData

/// A sheet that lets the user pick a food from the catalog, choose a quantity +
/// unit, preview the live grams and calories, then hand the choice back.
struct FoodPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]

    @AppStorage("portion.units") private var unitsPref = "metric"

    let onPick: (FoodItem, Double, MeasureUnit) -> Void

    @State private var search = ""
    @State private var selected: FoodItem?
    @State private var quantity: Double = 100
    @State private var unit: MeasureUnit = .gram

    private var filtered: [FoodItem] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return foods }
        return foods.filter { $0.name.lowercased().contains(q) }
    }

    private var grouped: [(category: FoodCategory, items: [FoodItem])] {
        Dictionary(grouping: filtered) { FoodCategory.from($0.category) }
            .map { (category: $0.key, items: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    var body: some View {
        Group {
            if let food = selected {
                quantityPicker(for: food)
            } else {
                foodList
            }
        }
        .background(Brand.pageBackground)
        .navigationTitle(selected?.name ?? "Add Ingredient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if selected == nil {
                    Button("Cancel") { dismiss() }
                } else {
                    Button("Back") { withAnimation(Brand.ease(0.2)) { selected = nil } }
                }
            }
        }
    }

    // MARK: - Food list

    private var foodList: some View {
        List {
            if filtered.isEmpty {
                Text("No foods match \"\(search)\".")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(grouped, id: \.category.id) { group in
                    Section(group.category.label) {
                        ForEach(group.items) { food in
                            Button {
                                Haptics.tap()
                                quantity = defaultQuantity
                                unit = defaultUnit
                                withAnimation(Brand.ease(0.2)) { selected = food }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(food.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Brand.text)
                                        Text("\(Format.kcal(food.kcalPer100)) kcal / 100 g")
                                            .font(Brand.mono(11))
                                            .foregroundStyle(Brand.text3)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityHint("Choose quantity")
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $search, prompt: "Search foods")
    }

    // MARK: - Quantity picker

    private func quantityPicker(for food: FoodItem) -> some View {
        let stubGrams = NutritionEngine.grams(for: quantity, unit: unit, food: food)
        let kcal = food.kcalPer100 * stubGrams / 100.0
        let units = NutritionEngine.availableUnits(for: food)
        return Form {
            Section("Amount") {
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("Qty", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .accessibilityLabel("Quantity")
                }
                Picker("Unit", selection: $unit) {
                    ForEach(units) { u in Text(u.longLabel).tag(u) }
                }
            }

            Section("Preview") {
                LabeledContent("Weight", value: Format.grams(stubGrams))
                LabeledContent("Calories", value: "\(Format.kcal(kcal)) kcal")
                LabeledContent("Protein", value: Format.grams(food.proteinPer100 * stubGrams / 100))
                LabeledContent("Carbs", value: Format.grams(food.carbsPer100 * stubGrams / 100))
                LabeledContent("Fat", value: Format.grams(food.fatPer100 * stubGrams / 100))
            }

            Section {
                Button {
                    onPick(food, max(0, quantity), unit)
                    dismiss()
                } label: {
                    Text("Add to recipe")
                }
                .buttonStyle(InkButtonStyle())
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .disabled(quantity <= 0)
            }
        }
        .scrollContentBackground(.hidden)
    }

    // MARK: - Defaults

    private var defaultUnit: MeasureUnit {
        unitsPref == "imperial" ? .ounce : .gram
    }

    private var defaultQuantity: Double {
        unitsPref == "imperial" ? 3 : 100
    }
}
