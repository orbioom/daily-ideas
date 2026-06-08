import SwiftUI
import SwiftData

struct FoodsView: View {
    @Query(sort: \FoodItem.name) private var foods: [FoodItem]
    @Environment(\.modelContext) private var ctx

    @State private var searchText = ""
    @State private var showCustomOnly = false
    @State private var showFavoritesOnly = false
    @State private var selectedCategory: String = "All"
    @State private var editFood: FoodItem? = nil
    @State private var showCreateFood = false
    @State private var foodToDelete: FoodItem? = nil

    private let categories = ["All", "Protein", "Grain", "Fruit", "Veg", "Dairy", "Snack", "Drink"]

    private var filtered: [FoodItem] {
        var result = foods
        if showCustomOnly    { result = result.filter { $0.isCustom } }
        if showFavoritesOnly { result = result.filter { $0.isFavorite } }
        if selectedCategory != "All" { result = result.filter { $0.category == selectedCategory } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                VStack(spacing: 0) {
                    filterStrip

                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "square.grid.2x2",
                            title: "No foods",
                            message: searchText.isEmpty ? "Add a custom food to get started." : "No foods match your search."
                        )
                        .padding(.top, 40)
                        Spacer()
                    } else {
                        List {
                            ForEach(filtered) { food in
                                Button {
                                    if food.isCustom {
                                        editFood = food
                                        Haptics.tap()
                                    }
                                } label: {
                                    FoodRow(food: food)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Brand.hairline)
                                .swipeActions(edge: .trailing) {
                                    if food.isCustom {
                                        Button(role: .destructive) {
                                            foodToDelete = food
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    Button {
                                        food.isFavorite.toggle()
                                        try? ctx.save()
                                        Haptics.tap()
                                    } label: {
                                        Label(
                                            food.isFavorite ? "Unfavorite" : "Favorite",
                                            systemImage: food.isFavorite ? "heart.slash.fill" : "heart.fill"
                                        )
                                    }
                                    .tint(Brand.magic)
                                }
                                .swipeActions(edge: .leading) {
                                    if food.isCustom {
                                        Button {
                                            editFood = food
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Brand.info)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Foods")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateFood = true
                        Haptics.tap()
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Create custom food")
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search catalog…")
        }
        .sheet(isPresented: $showCreateFood) {
            CustomFoodView(editingFood: nil)
        }
        .sheet(item: $editFood) { food in
            CustomFoodView(editingFood: food)
        }
        .confirmationDialog(
            "Delete \(foodToDelete?.name ?? "food")?",
            isPresented: Binding(
                get: { foodToDelete != nil },
                set: { if !$0 { foodToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let food = foodToDelete {
                    ctx.delete(food)
                    try? ctx.save()
                    Haptics.warning()
                }
                foodToDelete = nil
            }
            Button("Cancel", role: .cancel) { foodToDelete = nil }
        } message: {
            Text("This will remove the food from the catalog. Diary entries referencing it will keep their recorded nutrition.")
        }
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Favorites", systemImage: "heart.fill", isActive: showFavoritesOnly) {
                    showFavoritesOnly.toggle()
                    Haptics.selection()
                }
                FilterChip(label: "My Foods", systemImage: "person.fill", isActive: showCustomOnly) {
                    showCustomOnly.toggle()
                    Haptics.selection()
                }
                ForEach(categories, id: \.self) { cat in
                    FilterChip(label: cat, systemImage: nil, isActive: selectedCategory == cat) {
                        selectedCategory = cat
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Custom food editor

struct CustomFoodView: View {
    var editingFood: FoodItem?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var servingDesc: String = ""
    @State private var caloriesText: String = ""
    @State private var proteinText: String = ""
    @State private var carbsText: String = ""
    @State private var fatText: String = ""
    @State private var category: String = "Protein"
    @State private var validationError: String = ""

    private let categories = ["Protein", "Grain", "Fruit", "Veg", "Dairy", "Snack", "Drink", "Other"]
    private var isEditing: Bool { editingFood != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section {
                        fieldRow(label: "Food Name", text: $name, placeholder: "e.g. Chicken Breast")
                        fieldRow(label: "Brand (optional)", text: $brand, placeholder: "e.g. Perdue")
                        fieldRow(label: "Serving Description", text: $servingDesc, placeholder: "e.g. 3 oz (85g)")
                    } header: {
                        Text("Basic Info").foregroundStyle(Brand.text3)
                    }

                    Section {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) { cat in
                                Text(cat).tag(cat)
                            }
                        }
                    } header: {
                        Text("Category").foregroundStyle(Brand.text3)
                    }

                    Section {
                        numericRow(label: "Calories (kcal)", text: $caloriesText)
                        numericRow(label: "Protein (g)",     text: $proteinText)
                        numericRow(label: "Carbs (g)",       text: $carbsText)
                        numericRow(label: "Fat (g)",         text: $fatText)
                    } header: {
                        Text("Per Serving Nutrition").foregroundStyle(Brand.text3)
                    }

                    if !validationError.isEmpty {
                        Section {
                            Text(validationError)
                                .foregroundStyle(Brand.danger)
                                .font(.subheadline)
                        }
                    }

                    Section {
                        Button(isEditing ? "Save Changes" : "Add Food") {
                            save()
                        }
                        .foregroundStyle(Brand.magic)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(isEditing ? "Edit Food" : "New Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text2)
                }
            }
            .onAppear(perform: loadExisting)
        }
    }

    private func fieldRow(label: String, text: Binding<String>, placeholder: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Brand.text2)
            Spacer()
            TextField(placeholder, text: text)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Brand.text)
        }
    }

    private func numericRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Brand.text2)
            Spacer()
            TextField("0", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .foregroundStyle(Brand.text)
        }
    }

    private func loadExisting() {
        guard let f = editingFood else { return }
        name = f.name
        brand = f.brand
        servingDesc = f.servingDesc
        caloriesText = String(format: "%.1f", f.calories)
        proteinText  = String(format: "%.1f", f.protein)
        carbsText    = String(format: "%.1f", f.carbs)
        fatText      = String(format: "%.1f", f.fat)
        category = f.category
    }

    private func save() {
        validationError = ""
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Food name is required."
            return
        }
        guard !servingDesc.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationError = "Serving description is required."
            return
        }
        guard let cal = Double(caloriesText), cal >= 0 else {
            validationError = "Enter a valid calorie value (0 or more)."
            return
        }
        let pro  = Double(proteinText) ?? 0
        let carb = Double(carbsText) ?? 0
        let fat  = Double(fatText) ?? 0
        guard pro >= 0, carb >= 0, fat >= 0 else {
            validationError = "Macro values must be 0 or greater."
            return
        }

        if let f = editingFood {
            f.name = name.trimmingCharacters(in: .whitespaces)
            f.brand = brand.trimmingCharacters(in: .whitespaces)
            f.servingDesc = servingDesc.trimmingCharacters(in: .whitespaces)
            f.calories = cal
            f.protein = pro
            f.carbs = carb
            f.fat = fat
            f.category = category
        } else {
            let food = FoodItem(
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand.trimmingCharacters(in: .whitespaces),
                servingDesc: servingDesc.trimmingCharacters(in: .whitespaces),
                calories: cal,
                protein: pro,
                carbs: carb,
                fat: fat,
                isCustom: true,
                category: category
            )
            ctx.insert(food)
        }
        try? ctx.save()
        Haptics.success()
        dismiss()
    }
}
