import Foundation
import SwiftData

enum SeedData {
    @MainActor
    static func populate(_ context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)

        let pasta = Recipe(name: "Garlic Butter Pasta", summary: "Fast weeknight pasta with a silky garlic butter sauce.",
                           course: .dinner, servings: 2, prepMinutes: 5, cookMinutes: 15, colorHex: 0xB0673E)
        addIngredients(pasta, [
            ("Spaghetti", 200, .g, .pantry), ("Butter", 3, .tbsp, .dairy),
            ("Garlic", 3, .clove, .produce), ("Parmesan", 40, .g, .dairy),
            ("Parsley", 1, .tbsp, .produce), ("Salt", 0, .pinch, .spices),
        ], in: context)
        addSteps(pasta, [
            "Boil the spaghetti in well-salted water until al dente.",
            "Melt butter in a pan, add sliced garlic, cook until fragrant.",
            "Toss drained pasta with the garlic butter and a splash of pasta water.",
            "Off the heat, stir in parmesan and parsley. Serve.",
        ], in: context)

        let bowl = Recipe(name: "Halloumi Grain Bowl", summary: "Bright, filling lunch bowl with crispy halloumi.",
                          course: .lunch, servings: 2, prepMinutes: 10, cookMinutes: 10, colorHex: 0x3E9E78)
        addIngredients(bowl, [
            ("Quinoa", 150, .g, .pantry), ("Halloumi", 200, .g, .dairy),
            ("Cherry Tomatoes", 200, .g, .produce), ("Cucumber", 1, .none, .produce),
            ("Olive Oil", 2, .tbsp, .pantry), ("Lemon", 1, .none, .produce),
        ], in: context)
        addSteps(bowl, [
            "Cook quinoa according to the packet, then fluff and cool slightly.",
            "Pan-fry sliced halloumi until golden on both sides.",
            "Chop tomatoes and cucumber; dress with olive oil and lemon.",
            "Build the bowls: quinoa, veg, halloumi on top.",
        ], in: context)

        let oats = Recipe(name: "Overnight Oats", summary: "Make-ahead breakfast, ready when you wake.",
                          course: .breakfast, servings: 1, prepMinutes: 5, cookMinutes: 0, favorite: true, colorHex: 0xC0953E)
        addIngredients(oats, [
            ("Rolled Oats", 50, .g, .pantry), ("Milk", 120, .ml, .dairy),
            ("Yogurt", 60, .g, .dairy), ("Honey", 1, .tbsp, .pantry),
            ("Blueberries", 60, .g, .produce),
        ], in: context)
        addSteps(oats, [
            "Combine oats, milk, yogurt, and honey in a jar.",
            "Stir, cover, and refrigerate overnight.",
            "Top with blueberries before eating.",
        ], in: context)

        [pasta, bowl, oats].forEach { context.insert($0) }

        // A few days of plan so Grocery has something to generate.
        context.insert(MealPlan(date: today, mealType: .breakfast, servings: 1, recipe: oats))
        context.insert(MealPlan(date: today, mealType: .dinner, servings: 2, recipe: pasta))
        if let d1 = cal.date(byAdding: .day, value: 1, to: today) {
            context.insert(MealPlan(date: d1, mealType: .lunch, servings: 2, recipe: bowl))
            context.insert(MealPlan(date: d1, mealType: .dinner, servings: 4, recipe: pasta))
        }

        try? context.save()
    }

    @MainActor
    private static func addIngredients(_ recipe: Recipe, _ list: [(String, Double, Unit, Aisle)], in context: ModelContext) {
        for (i, t) in list.enumerated() {
            let ing = Ingredient(name: t.0, quantity: t.1, unit: t.2, aisle: t.3, order: i, recipe: recipe)
            context.insert(ing)
        }
    }

    @MainActor
    private static func addSteps(_ recipe: Recipe, _ list: [String], in context: ModelContext) {
        for (i, s) in list.enumerated() {
            context.insert(Step(text: s, order: i, recipe: recipe))
        }
    }
}
