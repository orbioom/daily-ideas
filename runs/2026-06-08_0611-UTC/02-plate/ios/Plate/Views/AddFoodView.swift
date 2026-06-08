import SwiftUI
import SwiftData

// MARK: - Add food flow (sheet presented from DiaryView)

struct AddFoodFlow: View {
    let meal: Meal
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @State private var selected: FoodItem? = nil
    @State private var showCustomFood = false

    var body: some View {
        NavigationStack {
            FoodSearchView(onSelect: { food in
                selected = food
            }, onCreateCustom: {
                showCustomFood = true
            })
            .navigationTitle("Add to \(meal.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text2)
                }
            }
        }
        .sheet(item: $selected) { food in
            ServingSheet(food: food, meal: meal, date: date) {
                dismiss()
            }
        }
        .sheet(isPresented: $showCustomFood) {
            CustomFoodView(editingFood: nil)
        }
    }
}

// MARK: - Food search view

struct FoodSearchView: View {
    var onSelect: (FoodItem) -> Void
    var onCreateCustom: () -> Void

    @Query(sort: \FoodItem.name) private var allFoods: [FoodItem]
    @State private var searchText = ""
    @State private var showFavoritesOnly = false
    @State private var selectedCategory: String = "All"

    private let categories = ["All", "Protein", "Grain", "Fruit", "Veg", "Dairy", "Snack", "Drink"]

    private var filtered: [FoodItem] {
        var result = allFoods
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "Favorites", systemImage: "heart.fill", isActive: showFavoritesOnly) {
                            showFavoritesOnly.toggle()
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

                if filtered.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results",
                        message: "Try a different search term, or create a custom food."
                    )
                    .padding(.top, 40)
                } else if filtered.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: "No foods found",
                        message: "Add custom foods to build your personal catalog."
                    )
                    .padding(.top, 40)
                } else {
                    List {
                        ForEach(filtered) { food in
                            Button {
                                Haptics.tap()
                                onSelect(food)
                            } label: {
                                FoodRow(food: food)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Brand.hairline)
                        }

                        Section {
                            Button(action: onCreateCustom) {
                                Label("Create custom food", systemImage: "plus.circle.fill")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Brand.magic)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search foods…")
    }
}

// MARK: - Serving sheet

struct ServingSheet: View {
    let food: FoodItem
    let meal: Meal
    let date: Date
    var onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @State private var servings: Double = 1.0
    @State private var servingText: String = "1"

    private var cal: Double { food.calories * servings }
    private var pro: Double { food.protein * servings }
    private var carb: Double { food.carbs * servings }
    private var fat: Double { food.fat * servings }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 6) {
                                if !food.brand.isEmpty {
                                    Eyebrow(text: food.brand)
                                }
                                Text(food.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(Brand.text)
                                Text(food.servingDesc)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text3)
                                HStack {
                                    StatusDot(color: Brand.magic)
                                    Text("Adding to \(meal.displayName)")
                                        .font(.caption)
                                        .foregroundStyle(Brand.text3)
                                }
                            }
                        }

                        GlassCard {
                            VStack(spacing: 16) {
                                Eyebrow(text: "Servings")

                                HStack(spacing: 16) {
                                    Button {
                                        let newVal = max(0.25, servings - 0.25)
                                        servings = newVal
                                        servingText = Format.servings(newVal)
                                        Haptics.selection()
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Brand.text2)
                                    }
                                    .accessibilityLabel("Decrease servings")

                                    TextField("", text: $servingText)
                                        .font(Brand.mono(32, weight: .semibold))
                                        .foregroundStyle(Brand.text)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                        .frame(maxWidth: 100)
                                        .onChange(of: servingText) { _, val in
                                            if let d = Double(val), d > 0 { servings = d }
                                        }

                                    Button {
                                        let newVal = servings + 0.25
                                        servings = newVal
                                        servingText = Format.servings(newVal)
                                        Haptics.selection()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Brand.magic)
                                    }
                                    .accessibilityLabel("Increase servings")
                                }

                                // Quick servings
                                HStack(spacing: 8) {
                                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { quick in
                                        Button {
                                            servings = quick
                                            servingText = Format.servings(quick)
                                            Haptics.selection()
                                        } label: {
                                            Text(Format.servings(quick))
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(servings == quick ? .white : Brand.text2)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    servings == quick ? AnyView(Brand.inkGradient) : AnyView(Brand.hairline.opacity(0.6)),
                                                    in: Capsule()
                                                )
                                        }
                                        .accessibilityLabel("\(Format.servings(quick)) servings")
                                        .accessibilityAddTraits(servings == quick ? [.isSelected] : [])
                                    }
                                }
                            }
                        }

                        // Live preview
                        GlassCard {
                            VStack(spacing: 12) {
                                Eyebrow(text: "Nutrition Preview")
                                HStack {
                                    nutrientCell(label: "Calories", value: Format.kcalShort(cal), color: Brand.magic)
                                    Divider().frame(height: 44)
                                    nutrientCell(label: "Protein", value: Format.grams(pro), color: Brand.danger)
                                    Divider().frame(height: 44)
                                    nutrientCell(label: "Carbs", value: Format.grams(carb), color: Brand.warn)
                                    Divider().frame(height: 44)
                                    nutrientCell(label: "Fat", value: Format.grams(fat), color: Brand.info)
                                }
                            }
                        }

                        Button("Add to \(meal.displayName)") {
                            addEntry()
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(servings <= 0)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Serving Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private func nutrientCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(16, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }

    private func addEntry() {
        guard servings > 0 else { return }
        let entry = DiaryEntry(
            day: date,
            meal: meal,
            foodName: food.name,
            servingDesc: food.servingDesc,
            servings: servings,
            calories: food.calories * servings,
            protein: food.protein * servings,
            carbs: food.carbs * servings,
            fat: food.fat * servings,
            food: food
        )
        ctx.insert(entry)
        try? ctx.save()
        Haptics.success()
        dismiss()
        onAdded()
    }
}
