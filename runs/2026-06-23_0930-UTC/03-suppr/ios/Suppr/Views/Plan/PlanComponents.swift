import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// A draggable chip representing a recipe in the bottom drawer. Carries the
/// recipe's UUID string as the drag payload.
struct DraggableRecipeChip: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 8) {
            RecipeThumbnail(recipe: recipe, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(recipe.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                Text("\(recipe.totalMinutes) min")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: 180)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.hairline, lineWidth: 1))
        .draggable(recipe.id.uuidString) {
            // Drag preview.
            HStack(spacing: 6) {
                Image(systemName: "fork.knife").foregroundStyle(.white)
                Text(recipe.name).font(.caption.weight(.semibold)).foregroundStyle(.white)
            }
            .padding(8)
            .background(Theme.terracotta, in: Capsule())
        }
        .accessibilityLabel("\(recipe.name), draggable recipe")
        .accessibilityHint("Drag onto a day and meal to plan it")
    }
}

/// One day in the week plan with three meal slots.
struct DayCard: View {
    let day: Date
    let isToday: Bool
    let mealsFor: (MealSlot) -> [PlannedMeal]
    let onTapAdd: (MealSlot) -> Void
    let onDrop: (Recipe, MealSlot) -> Void
    let onRemove: (PlannedMeal) -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(WeekHelper.weekdayShort.string(from: day).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isToday ? Theme.terracotta : Theme.secondaryText)
                    Text(WeekHelper.dayNumber.string(from: day))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.primaryText)
                }
                .frame(width: 44, alignment: .leading)
                if isToday {
                    TagPill(text: "Today")
                }
                Spacer()
            }

            ForEach(MealSlot.allCases) { slot in
                MealSlotRow(
                    slot: slot,
                    meals: mealsFor(slot),
                    onTapAdd: { onTapAdd(slot) },
                    onDrop: { recipe in onDrop(recipe, slot) },
                    onRemove: onRemove,
                    resolveRecipe: resolveRecipe
                )
            }
        }
        .cardSurface()
    }

    private func resolveRecipe(_ idString: String) -> Recipe? {
        guard let uuid = UUID(uuidString: idString) else { return nil }
        let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.id == uuid })
        return try? context.fetch(descriptor).first
    }
}

/// A single meal slot that accepts drops and shows planned meals.
struct MealSlotRow: View {
    let slot: MealSlot
    let meals: [PlannedMeal]
    let onTapAdd: () -> Void
    let onDrop: (Recipe) -> Void
    let onRemove: (PlannedMeal) -> Void
    let resolveRecipe: (String) -> Recipe?

    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: slot.symbol)
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
                Text(slot.rawValue)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Button(action: onTapAdd) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.terracotta)
                }
                .accessibilityLabel("Add a recipe to \(slot.rawValue)")
            }

            if meals.isEmpty {
                emptySlot
            } else {
                ForEach(meals) { meal in
                    PlannedMealChip(meal: meal, onRemove: { onRemove(meal) })
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isTargeted ? Theme.terracotta.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isTargeted ? Theme.terracotta : Color.clear, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
        )
        .dropDestination(for: String.self) { items, _ in
            guard let first = items.first, let recipe = resolveRecipe(first) else { return false }
            onDrop(recipe)
            return true
        } isTargeted: { isTargeted = $0 }
    }

    private var emptySlot: some View {
        HStack {
            Text("Empty — drop a recipe here")
                .font(.caption)
                .foregroundStyle(Theme.secondaryText.opacity(0.8))
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }
}

/// A planned recipe shown inside a slot, with serving stepper and remove.
struct PlannedMealChip: View {
    @Bindable var meal: PlannedMeal
    let onRemove: () -> Void

    @Environment(\.modelContext) private var context

    var body: some View {
        HStack(spacing: 10) {
            if let recipe = meal.recipe {
                RecipeThumbnail(recipe: recipe, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recipe.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    Text("\(meal.servings) servings")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Stepper("", value: Binding(
                    get: { meal.servings },
                    set: { newVal in
                        PlanStore(context: context).updateServings(meal, to: newVal)
                        regenerate()
                    }
                ), in: 1...20)
                .labelsHidden()
                .scaleEffect(0.82)
                .frame(width: 86)
                .accessibilityLabel("Servings for \(recipe.name)")
                .accessibilityValue("\(meal.servings)")
                Button(action: { onRemove() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityLabel("Remove \(recipe.name) from plan")
            } else {
                Text("Recipe unavailable")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.secondaryText)
                }
                .accessibilityLabel("Remove unavailable meal")
            }
        }
        .padding(8)
        .background(Theme.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func regenerate() {
        let all = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []
        PlanStore(context: context).regenerateGroceryList(from: all)
    }
}

/// Sheet listing recipes to pick when tapping the + on a slot.
struct RecipePickerSheet: View {
    var onPick: (Recipe) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @State private var search = ""

    private var filtered: [Recipe] {
        search.isEmpty ? recipes : recipes.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(search) }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if filtered.isEmpty {
                    EmptyStateView(icon: "magnifyingglass", title: "No matches",
                                   message: "Try another search term.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filtered) { recipe in
                                Button {
                                    onPick(recipe)
                                    Haptics.success()
                                    dismiss()
                                } label: {
                                    RecipeRow(recipe: recipe)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Pick a Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
