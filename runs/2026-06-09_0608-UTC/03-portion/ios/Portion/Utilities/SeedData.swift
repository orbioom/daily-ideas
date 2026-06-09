import Foundation
import SwiftData

/// Seeds the on-device food catalog (~60 realistic items) and a couple of
/// example recipes on first launch, so the catalog, lists, and detail charts are
/// never empty for a brand-new user.
enum SeedData {

    /// Per-100 g spec used to build a `FoodItem`. Values are realistic-ish USDA
    /// style figures; piece/cup grams enable household-measure units.
    private struct Spec {
        let name: String
        let cat: FoodCategory
        let kcal, p, c, f, fiber: Double
        var piece: Double = 0
        var cup: Double = 0
    }

    private static let catalog: [Spec] = [
        // Grains
        Spec(name: "White rice, cooked", cat: .grains, kcal: 130, p: 2.7, c: 28, f: 0.3, fiber: 0.4, cup: 158),
        Spec(name: "Brown rice, cooked", cat: .grains, kcal: 123, p: 2.7, c: 26, f: 1.0, fiber: 1.6, cup: 195),
        Spec(name: "Rolled oats, dry", cat: .grains, kcal: 389, p: 16.9, c: 66, f: 6.9, fiber: 10.6, cup: 81),
        Spec(name: "Pasta, cooked", cat: .grains, kcal: 158, p: 5.8, c: 31, f: 0.9, fiber: 1.8, cup: 140),
        Spec(name: "Quinoa, cooked", cat: .grains, kcal: 120, p: 4.4, c: 21, f: 1.9, fiber: 2.8, cup: 185),
        Spec(name: "All-purpose flour", cat: .grains, kcal: 364, p: 10.3, c: 76, f: 1.0, fiber: 2.7, cup: 125),
        Spec(name: "Whole wheat bread", cat: .grains, kcal: 247, p: 13, c: 41, f: 3.4, fiber: 7, piece: 28),
        Spec(name: "White bread", cat: .grains, kcal: 266, p: 9, c: 49, f: 3.2, fiber: 2.7, piece: 25),
        Spec(name: "Corn tortilla", cat: .grains, kcal: 218, p: 5.7, c: 45, f: 2.9, fiber: 6.3, piece: 26),
        Spec(name: "Couscous, cooked", cat: .grains, kcal: 112, p: 3.8, c: 23, f: 0.2, fiber: 1.4, cup: 157),

        // Protein
        Spec(name: "Chicken breast, cooked", cat: .protein, kcal: 165, p: 31, c: 0, f: 3.6, fiber: 0),
        Spec(name: "Chicken thigh, cooked", cat: .protein, kcal: 209, p: 26, c: 0, f: 10.9, fiber: 0),
        Spec(name: "Ground beef 85/15, cooked", cat: .protein, kcal: 250, p: 26, c: 0, f: 15, fiber: 0),
        Spec(name: "Salmon, cooked", cat: .protein, kcal: 206, p: 22, c: 0, f: 12, fiber: 0),
        Spec(name: "Tuna, canned in water", cat: .protein, kcal: 116, p: 26, c: 0, f: 0.8, fiber: 0),
        Spec(name: "Shrimp, cooked", cat: .protein, kcal: 99, p: 24, c: 0.2, f: 0.3, fiber: 0),
        Spec(name: "Egg, whole", cat: .protein, kcal: 143, p: 12.6, c: 0.7, f: 9.5, fiber: 0, piece: 50),
        Spec(name: "Egg white", cat: .protein, kcal: 52, p: 11, c: 0.7, f: 0.2, fiber: 0, piece: 33),
        Spec(name: "Pork loin, cooked", cat: .protein, kcal: 242, p: 27, c: 0, f: 14, fiber: 0),
        Spec(name: "Turkey breast, cooked", cat: .protein, kcal: 135, p: 30, c: 0, f: 1, fiber: 0),
        Spec(name: "Tofu, firm", cat: .protein, kcal: 144, p: 17, c: 2.8, f: 8.7, fiber: 2.3, cup: 252),
        Spec(name: "Tempeh", cat: .protein, kcal: 192, p: 20, c: 7.6, f: 11, fiber: 0),
        Spec(name: "Bacon, cooked", cat: .protein, kcal: 541, p: 37, c: 1.4, f: 42, fiber: 0, piece: 8),

        // Dairy
        Spec(name: "Whole milk", cat: .dairy, kcal: 61, p: 3.2, c: 4.8, f: 3.3, fiber: 0, cup: 244),
        Spec(name: "Skim milk", cat: .dairy, kcal: 34, p: 3.4, c: 5, f: 0.1, fiber: 0, cup: 245),
        Spec(name: "Greek yogurt, plain", cat: .dairy, kcal: 59, p: 10, c: 3.6, f: 0.4, fiber: 0, cup: 245),
        Spec(name: "Cheddar cheese", cat: .dairy, kcal: 403, p: 25, c: 1.3, f: 33, fiber: 0),
        Spec(name: "Mozzarella cheese", cat: .dairy, kcal: 280, p: 28, c: 3.1, f: 17, fiber: 0),
        Spec(name: "Parmesan cheese", cat: .dairy, kcal: 431, p: 38, c: 4.1, f: 29, fiber: 0),
        Spec(name: "Cottage cheese", cat: .dairy, kcal: 98, p: 11, c: 3.4, f: 4.3, fiber: 0, cup: 226),
        Spec(name: "Heavy cream", cat: .dairy, kcal: 340, p: 2.8, c: 2.8, f: 36, fiber: 0, cup: 238),
        Spec(name: "Sour cream", cat: .dairy, kcal: 198, p: 2.4, c: 4.6, f: 19, fiber: 0, cup: 230),

        // Vegetable
        Spec(name: "Broccoli", cat: .vegetable, kcal: 34, p: 2.8, c: 6.6, f: 0.4, fiber: 2.6, cup: 91),
        Spec(name: "Spinach, raw", cat: .vegetable, kcal: 23, p: 2.9, c: 3.6, f: 0.4, fiber: 2.2, cup: 30),
        Spec(name: "Carrot", cat: .vegetable, kcal: 41, p: 0.9, c: 9.6, f: 0.2, fiber: 2.8, piece: 61, cup: 128),
        Spec(name: "Sweet potato", cat: .vegetable, kcal: 86, p: 1.6, c: 20, f: 0.1, fiber: 3, piece: 130, cup: 200),
        Spec(name: "Potato", cat: .vegetable, kcal: 77, p: 2, c: 17, f: 0.1, fiber: 2.2, piece: 173),
        Spec(name: "Tomato", cat: .vegetable, kcal: 18, p: 0.9, c: 3.9, f: 0.2, fiber: 1.2, piece: 123),
        Spec(name: "Bell pepper", cat: .vegetable, kcal: 31, p: 1, c: 6, f: 0.3, fiber: 2.1, piece: 119, cup: 149),
        Spec(name: "Onion", cat: .vegetable, kcal: 40, p: 1.1, c: 9.3, f: 0.1, fiber: 1.7, piece: 110, cup: 160),
        Spec(name: "Mushrooms", cat: .vegetable, kcal: 22, p: 3.1, c: 3.3, f: 0.3, fiber: 1, cup: 70),
        Spec(name: "Zucchini", cat: .vegetable, kcal: 17, p: 1.2, c: 3.1, f: 0.3, fiber: 1, piece: 196, cup: 124),

        // Fruit
        Spec(name: "Banana", cat: .fruit, kcal: 89, p: 1.1, c: 23, f: 0.3, fiber: 2.6, piece: 118),
        Spec(name: "Apple", cat: .fruit, kcal: 52, p: 0.3, c: 14, f: 0.2, fiber: 2.4, piece: 182),
        Spec(name: "Orange", cat: .fruit, kcal: 47, p: 0.9, c: 12, f: 0.1, fiber: 2.4, piece: 131),
        Spec(name: "Blueberries", cat: .fruit, kcal: 57, p: 0.7, c: 14, f: 0.3, fiber: 2.4, cup: 148),
        Spec(name: "Strawberries", cat: .fruit, kcal: 32, p: 0.7, c: 7.7, f: 0.3, fiber: 2, cup: 152),
        Spec(name: "Avocado", cat: .fruit, kcal: 160, p: 2, c: 8.5, f: 14.7, fiber: 6.7, piece: 150),
        Spec(name: "Grapes", cat: .fruit, kcal: 69, p: 0.7, c: 18, f: 0.2, fiber: 0.9, cup: 151),
        Spec(name: "Mango", cat: .fruit, kcal: 60, p: 0.8, c: 15, f: 0.4, fiber: 1.6, cup: 165),

        // Fat / Oil
        Spec(name: "Olive oil", cat: .fatOil, kcal: 884, p: 0, c: 0, f: 100, fiber: 0, cup: 216),
        Spec(name: "Butter", cat: .fatOil, kcal: 717, p: 0.9, c: 0.1, f: 81, fiber: 0, cup: 227),
        Spec(name: "Coconut oil", cat: .fatOil, kcal: 892, p: 0, c: 0, f: 99, fiber: 0, cup: 218),
        Spec(name: "Mayonnaise", cat: .fatOil, kcal: 680, p: 1, c: 0.6, f: 75, fiber: 0, cup: 220),

        // Legume
        Spec(name: "Black beans, cooked", cat: .legume, kcal: 132, p: 8.9, c: 24, f: 0.5, fiber: 8.7, cup: 172),
        Spec(name: "Chickpeas, cooked", cat: .legume, kcal: 164, p: 8.9, c: 27, f: 2.6, fiber: 7.6, cup: 164),
        Spec(name: "Lentils, cooked", cat: .legume, kcal: 116, p: 9, c: 20, f: 0.4, fiber: 7.9, cup: 198),
        Spec(name: "Kidney beans, cooked", cat: .legume, kcal: 127, p: 8.7, c: 23, f: 0.5, fiber: 6.4, cup: 177),

        // Nut / Seed
        Spec(name: "Almonds", cat: .nutSeed, kcal: 579, p: 21, c: 22, f: 50, fiber: 12.5, cup: 143),
        Spec(name: "Peanut butter", cat: .nutSeed, kcal: 588, p: 25, c: 20, f: 50, fiber: 6, cup: 258),
        Spec(name: "Walnuts", cat: .nutSeed, kcal: 654, p: 15, c: 14, f: 65, fiber: 6.7, cup: 117),
        Spec(name: "Chia seeds", cat: .nutSeed, kcal: 486, p: 17, c: 42, f: 31, fiber: 34, cup: 168),

        // Sweetener
        Spec(name: "Sugar, granulated", cat: .sweetener, kcal: 387, p: 0, c: 100, f: 0, fiber: 0, cup: 200),
        Spec(name: "Honey", cat: .sweetener, kcal: 304, p: 0.3, c: 82, f: 0, fiber: 0.2, cup: 339),
        Spec(name: "Maple syrup", cat: .sweetener, kcal: 260, p: 0, c: 67, f: 0.1, fiber: 0, cup: 322),

        // Other
        Spec(name: "Dark chocolate 70%", cat: .other, kcal: 598, p: 7.8, c: 46, f: 43, fiber: 11),
        Spec(name: "Tomato sauce", cat: .other, kcal: 29, p: 1.6, c: 5.3, f: 0.4, fiber: 1.5, cup: 245)
    ]

    /// First-launch seeding: foods + example recipes (both only when empty).
    static func seedIfNeeded(_ context: ModelContext) {
        let foodDescriptor = FetchDescriptor<FoodItem>()
        let existingFoods = (try? context.fetch(foodDescriptor)) ?? []
        guard existingFoods.isEmpty else { return }

        let byName = insertFoods(context)

        // Only seed example recipes if there are none (avoids duplicates on a
        // catalog-only re-seed via Settings).
        let recipeDescriptor = FetchDescriptor<Recipe>()
        let existingRecipes = (try? context.fetch(recipeDescriptor)) ?? []
        if existingRecipes.isEmpty {
            seedRecipes(context, foods: byName)
        }
        try? context.save()
    }

    /// Re-seed only the built-in food catalog (used by Settings reset). Assumes
    /// the caller has already removed existing foods.
    static func reseedFoods(_ context: ModelContext) {
        _ = insertFoods(context)
        try? context.save()
    }

    @discardableResult
    private static func insertFoods(_ context: ModelContext) -> [String: FoodItem] {
        var byName: [String: FoodItem] = [:]
        for spec in catalog {
            let item = FoodItem(name: spec.name,
                                category: spec.cat.rawValue,
                                kcalPer100: spec.kcal,
                                proteinPer100: spec.p,
                                carbsPer100: spec.c,
                                fatPer100: spec.f,
                                fiberPer100: spec.fiber,
                                gramsPerPiece: spec.piece,
                                gramsPerCup: spec.cup,
                                isCustom: false)
            context.insert(item)
            byName[spec.name] = item
        }
        return byName
    }

    /// Build a recipe ingredient from a seeded food, computing canonical grams.
    private static func ingredient(_ name: String,
                                   quantity: Double,
                                   unit: MeasureUnit,
                                   order: Int,
                                   foods: [String: FoodItem]) -> RecipeIngredient? {
        guard let food = foods[name] else { return nil }
        let grams = NutritionEngine.grams(for: quantity, unit: unit, food: food)
        return RecipeIngredient(from: food, grams: grams,
                                displayQuantity: quantity, unit: unit, order: order)
    }

    private static func seedRecipes(_ context: ModelContext, foods: [String: FoodItem]) {
        // Recipe 1 — favorited high-protein bowl.
        let bowl = Recipe(name: "Chicken & Rice Bowl", servings: 2,
                          notes: "Easy meal-prep staple.", isFavorite: true)
        context.insert(bowl)
        let bowlLines: [(String, Double, MeasureUnit)] = [
            ("Chicken breast, cooked", 300, .gram),
            ("White rice, cooked", 1.5, .cup),
            ("Broccoli", 1, .cup),
            ("Olive oil", 1, .tablespoon)
        ]
        for (i, line) in bowlLines.enumerated() {
            if let ing = ingredient(line.0, quantity: line.1, unit: line.2, order: i, foods: foods) {
                ing.recipe = bowl
                context.insert(ing)
            }
        }

        // Recipe 2 — a breakfast.
        let oats = Recipe(name: "Banana Oatmeal", servings: 1,
                          notes: "Cozy breakfast.", isFavorite: false)
        context.insert(oats)
        let oatLines: [(String, Double, MeasureUnit)] = [
            ("Rolled oats, dry", 0.5, .cup),
            ("Whole milk", 1, .cup),
            ("Banana", 1, .piece),
            ("Peanut butter", 1, .tablespoon),
            ("Honey", 1, .tablespoon)
        ]
        for (i, line) in oatLines.enumerated() {
            if let ing = ingredient(line.0, quantity: line.1, unit: line.2, order: i, foods: foods) {
                ing.recipe = oats
                context.insert(ing)
            }
        }
    }
}
