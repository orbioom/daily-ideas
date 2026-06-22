import SwiftUI
import SwiftData

struct FoodLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [NourishSettings]

    @State private var searchQuery: String = ""
    @State private var selectedCategory: FoodCategory? = nil
    @State private var showingLogFood = false
    @State private var selectedFood: FoodItem? = nil

    private var hapticsEnabled: Bool { settings.first?.hapticsEnabled ?? true }

    private var filteredFoods: [FoodItem] {
        var items = selectedCategory.map { FoodCatalog.items(in: $0) } ?? FoodCatalog.all
        if !searchQuery.isEmpty {
            let lower = searchQuery.lowercased()
            items = items.filter { $0.name.lowercased().contains(lower) }
        }
        return items
    }

    private var groupedFoods: [(category: FoodCategory, foods: [FoodItem])] {
        if selectedCategory != nil || !searchQuery.isEmpty {
            // Flatten when filtered
            return []
        }
        return FoodCategory.allCases.map { cat in
            (category: cat, foods: FoodCatalog.items(in: cat))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter
                    categoryFilter

                    // Food list
                    if searchQuery.isEmpty && selectedCategory == nil {
                        groupedFoodList
                    } else {
                        flatFoodList
                    }
                }
            }
            .navigationTitle("Food Library")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchQuery, prompt: "Search foods...")
            .sheet(item: $selectedFood) { food in
                LogFoodView(
                    defaultMealType: currentMealType(),
                    prefillFood: food
                )
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NourishTheme.Spacing.sm) {
                CategoryFilterChip(
                    label: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach(FoodCategory.allCases) { category in
                    CategoryFilterChip(
                        label: category.rawValue,
                        emoji: category.icon,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
            .padding(.vertical, NourishTheme.Spacing.sm)
        }
        .background(NourishTheme.background)
    }

    // MARK: - Grouped List (default view)

    private var groupedFoodList: some View {
        List {
            ForEach(FoodCategory.allCases) { category in
                Section {
                    ForEach(FoodCatalog.items(in: category)) { food in
                        FoodLibraryRow(food: food) {
                            quickLog(food)
                        } onAddToLog: {
                            selectedFood = food
                        }
                    }
                } header: {
                    HStack(spacing: 6) {
                        Text(category.icon)
                            .accessibilityHidden(true)
                        Text(category.rawValue)
                            .font(NourishTheme.Typography.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(NourishTheme.charcoal)
                        Spacer()
                        Text(category.description)
                            .font(NourishTheme.Typography.caption2)
                            .foregroundColor(NourishTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Flat List (filtered view)

    private var flatFoodList: some View {
        Group {
            if filteredFoods.isEmpty {
                VStack(spacing: NourishTheme.Spacing.md) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(NourishTheme.secondaryText.opacity(0.3))
                        .accessibilityHidden(true)
                    Text("No foods found for \"\(searchQuery)\"")
                        .font(NourishTheme.Typography.body)
                        .foregroundColor(NourishTheme.secondaryText)
                    Spacer()
                }
            } else {
                List(filteredFoods) { food in
                    FoodLibraryRow(food: food) {
                        quickLog(food)
                    } onAddToLog: {
                        selectedFood = food
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Actions

    private func quickLog(_ food: FoodItem) {
        let entry = FoodLogEntry(
            date: Date(),
            foodName: food.name,
            mealType: currentMealType().rawValue,
            portionNote: "medium",
            allergenTags: food.allergenTags
        )
        modelContext.insert(entry)

        if hapticsEnabled {
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }
    }

    private func currentMealType() -> MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<11: return .breakfast
        case 11..<15: return .lunch
        case 15..<18: return .snack
        case 18..<22: return .dinner
        default: return .snack
        }
    }
}

// MARK: - FoodLibraryRow

private struct FoodLibraryRow: View {
    let food: FoodItem
    let onQuickLog: () -> Void
    let onAddToLog: () -> Void

    @State private var didQuickLog = false

    var body: some View {
        HStack(spacing: NourishTheme.Spacing.sm) {
            // Category color dot
            Circle()
                .fill(NourishTheme.allergenColor(for: food.primaryAllergen))
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(food.name)
                    .font(NourishTheme.Typography.callout)
                    .foregroundColor(NourishTheme.charcoal)

                if food.allergenTags.isEmpty {
                    SafeBadge()
                } else {
                    AllergenBadgeRow(allergenTags: food.allergenTags, compact: true, maxVisible: 3)
                }
            }

            Spacer()

            // Quick-log button
            Button(action: {
                onQuickLog()
                didQuickLog = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    didQuickLog = false
                }
            }) {
                Image(systemName: didQuickLog ? "checkmark.circle.fill" : "plus.circle.fill")
                    .foregroundColor(didQuickLog ? NourishTheme.sage : NourishTheme.sage.opacity(0.7))
                    .font(.title3)
                    .animation(.spring(), value: didQuickLog)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(didQuickLog ? "Logged \(food.name)" : "Quick log \(food.name)")
        }
        .swipeActions(edge: .trailing) {
            Button(action: onAddToLog) {
                Label("Add to Log", systemImage: "square.and.pencil")
            }
            .tint(NourishTheme.sage)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(food.name), \(food.allergenTags.isEmpty ? "safe food" : food.allergenTags.joined(separator: ", "))")
    }
}

// MARK: - CategoryFilterChip

private struct CategoryFilterChip: View {
    let label: String
    var emoji: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(NourishTheme.Typography.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : NourishTheme.charcoal)
            .padding(.horizontal, NourishTheme.Spacing.sm)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? NourishTheme.sage : NourishTheme.card)
                    .shadow(color: NourishTheme.Shadow.card.color, radius: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
