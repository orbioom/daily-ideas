import Foundation
import SwiftData

/// Coordinates the meal plan and grocery-list regeneration. Owns the cross-model
/// operations the views call (assigning recipes, regenerating the list, etc.).
@MainActor
final class PlanStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Plan editing

    func assign(recipe: Recipe, to day: Date, slot: MealSlot, servings: Int) {
        let meal = PlannedMeal(day: day, slot: slot, servings: servings, recipe: recipe)
        context.insert(meal)
        save()
    }

    func remove(_ meal: PlannedMeal) {
        context.delete(meal)
        save()
    }

    func updateServings(_ meal: PlannedMeal, to servings: Int) {
        meal.servings = max(1, servings)
        save()
    }

    func clearWeek(days: [Date]) {
        let set = Set(days.map { Calendar.current.startOfDay(for: $0) })
        let all = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []
        for meal in all where set.contains(Calendar.current.startOfDay(for: meal.day)) {
            context.delete(meal)
        }
        save()
    }

    // MARK: - Grocery regeneration

    /// Rebuilds auto grocery items from the given planned meals while preserving
    /// manual items and the checked-state of lines that still apply.
    func regenerateGroceryList(from meals: [PlannedMeal]) {
        let existing = (try? context.fetch(FetchDescriptor<GroceryItem>())) ?? []

        // Preserve checked state per source key from the prior auto items.
        var priorChecked: [String: Bool] = [:]
        for item in existing where !item.isManual {
            priorChecked[item.sourceKey] = item.isChecked
        }

        // Delete old auto items; keep manual ones untouched.
        for item in existing where !item.isManual {
            context.delete(item)
        }

        let lines = GroceryEngine.aggregate(from: meals)
        for line in lines {
            let item = GroceryItem(
                name: line.name,
                quantity: line.quantity,
                unit: line.unit,
                aisle: line.aisle,
                isChecked: priorChecked[line.sourceKey] ?? false,
                isManual: false,
                isStaple: line.isStaple,
                sourceKey: line.sourceKey
            )
            context.insert(item)
        }
        save()
    }

    func addManualItem(name: String, quantity: Double, unit: String, aisle: Aisle) {
        let item = GroceryItem(
            name: name,
            quantity: quantity,
            unit: unit,
            aisle: aisle,
            isManual: true
        )
        context.insert(item)
        save()
    }

    func toggle(_ item: GroceryItem) {
        item.isChecked.toggle()
        save()
    }

    func delete(_ item: GroceryItem) {
        context.delete(item)
        save()
    }

    func clearChecked() {
        let all = (try? context.fetch(FetchDescriptor<GroceryItem>())) ?? []
        for item in all where item.isChecked {
            context.delete(item)
        }
        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            // Recoverable: surface nothing fatal; the next save retries.
            context.rollback()
        }
    }
}
