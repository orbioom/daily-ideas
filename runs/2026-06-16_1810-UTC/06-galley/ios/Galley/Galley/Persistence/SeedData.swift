import Foundation
import SwiftData

/// One-time seeding of bundled substitutions and example recipes.
enum SeedData {

    /// Seed everything if the store is empty. Idempotent — guarded by counts.
    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        seedSubstitutionsIfNeeded(context)
        seedRecipesIfNeeded(context)
    }

    // MARK: - Substitutions

    @MainActor
    static func seedSubstitutionsIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<SubstitutionEntry>(
            predicate: #Predicate { $0.isCustom == false }
        )
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        for (index, sub) in bundledSubstitutions.enumerated() {
            let entry = SubstitutionEntry(
                ingredient: sub.ingredient,
                note: sub.note,
                isCustom: false,
                createdAt: Date(timeIntervalSinceReferenceDate: Double(index))
            )
            entry.options = sub.options.enumerated().map { i, opt in
                SubstituteOption(text: opt.text, ratioNote: opt.ratio, sortOrder: i)
            }
            context.insert(entry)
        }
        try? context.save()
    }

    private struct SeedSub {
        let ingredient: String
        let note: String
        let options: [(text: String, ratio: String)]
    }

    private static let bundledSubstitutions: [SeedSub] = [
        .init(ingredient: "Buttermilk", note: "For 1 cup buttermilk.", options: [
            ("1 tbsp lemon juice + milk to make 1 cup", "Let stand 5 min"),
            ("1 tbsp white vinegar + milk to make 1 cup", "Let stand 5 min"),
            ("¾ cup plain yogurt + ¼ cup milk", "Whisk to thin"),
            ("1 cup milk + 1¾ tsp cream of tartar", "")
        ]),
        .init(ingredient: "Egg", note: "Per 1 large egg, for binding/moisture.", options: [
            ("¼ cup unsweetened applesauce", "Best in cakes & muffins"),
            ("1 mashed ripe banana", "Adds banana flavor"),
            ("1 tbsp ground flaxseed + 3 tbsp water", "Rest 5 min until gel"),
            ("3 tbsp aquafaba (chickpea liquid)", "Whisk for binding"),
            ("¼ cup silken tofu, blended", "For dense bakes")
        ]),
        .init(ingredient: "Self-Rising Flour", note: "Per 1 cup self-rising flour.", options: [
            ("1 cup all-purpose flour + 1½ tsp baking powder + ¼ tsp salt", "Whisk well")
        ]),
        .init(ingredient: "Cake Flour", note: "Per 1 cup cake flour.", options: [
            ("1 cup all-purpose flour, remove 2 tbsp, add 2 tbsp cornstarch", "Sift together")
        ]),
        .init(ingredient: "Butter (in baking)", note: "Per 1 cup butter.", options: [
            ("1 cup vegetable shortening", "1:1"),
            ("⅞ cup vegetable oil", "For some recipes"),
            ("1 cup coconut oil", "1:1, solid state"),
            ("1 cup unsweetened applesauce", "Lower fat, denser result")
        ]),
        .init(ingredient: "Vegetable Oil", note: "Per 1 cup oil in baking.", options: [
            ("1 cup melted butter", "1:1"),
            ("1 cup unsweetened applesauce", "Lower fat"),
            ("1 cup mashed banana", "Adds flavor")
        ]),
        .init(ingredient: "Brown Sugar", note: "Per 1 cup packed brown sugar.", options: [
            ("1 cup granulated sugar + 1 tbsp molasses", "Light brown"),
            ("1 cup granulated sugar + 2 tbsp molasses", "Dark brown"),
            ("1 cup granulated sugar", "In a pinch; less moisture")
        ]),
        .init(ingredient: "Powdered Sugar", note: "Per 1 cup powdered sugar.", options: [
            ("1 cup granulated sugar + 1 tbsp cornstarch, blended fine", "Blend until powdery")
        ]),
        .init(ingredient: "Baking Powder", note: "Per 1 tsp baking powder.", options: [
            ("¼ tsp baking soda + ½ tsp cream of tartar", "Mix fresh"),
            ("¼ tsp baking soda + ½ cup buttermilk", "Reduce other liquid")
        ]),
        .init(ingredient: "Baking Soda", note: "Per 1 tsp baking soda.", options: [
            ("3 tsp baking powder", "Reduce salt; affects texture")
        ]),
        .init(ingredient: "Cornstarch", note: "Per 1 tbsp cornstarch (thickening).", options: [
            ("2 tbsp all-purpose flour", "For thickening"),
            ("1 tbsp arrowroot powder", "1:1"),
            ("2 tsp tapioca starch", "")
        ]),
        .init(ingredient: "Heavy Cream", note: "Per 1 cup heavy cream.", options: [
            ("¾ cup milk + ⅓ cup melted butter", "Not for whipping"),
            ("1 cup evaporated milk", "For cooking"),
            ("1 cup coconut cream", "Dairy-free")
        ]),
        .init(ingredient: "Sour Cream", note: "Per 1 cup sour cream.", options: [
            ("1 cup plain Greek yogurt", "1:1"),
            ("1 cup plain yogurt", "1:1"),
            ("¾ cup buttermilk + ⅓ cup melted butter", "")
        ]),
        .init(ingredient: "Whole Milk", note: "Per 1 cup whole milk.", options: [
            ("1 cup any plant milk", "1:1"),
            ("½ cup evaporated milk + ½ cup water", ""),
            ("¾ cup skim milk + ¼ cup half-and-half", "")
        ]),
        .init(ingredient: "Honey", note: "Per 1 cup honey.", options: [
            ("1¼ cup granulated sugar + ¼ cup liquid", "Add the listed liquid"),
            ("1 cup maple syrup", "1:1"),
            ("1 cup agave nectar", "1:1")
        ]),
        .init(ingredient: "Cream of Tartar", note: "Per 1 tsp cream of tartar.", options: [
            ("1 tsp white vinegar", "For stabilizing whites"),
            ("1 tsp lemon juice", "")
        ]),
        .init(ingredient: "Fresh Herbs", note: "Per 1 tbsp fresh herbs.", options: [
            ("1 tsp dried herbs", "3:1 fresh-to-dried")
        ]),
        .init(ingredient: "Garlic", note: "Per 1 clove garlic.", options: [
            ("⅛ tsp garlic powder", ""),
            ("½ tsp minced jarred garlic", "")
        ]),
        .init(ingredient: "Wine (cooking)", note: "Per 1 cup wine.", options: [
            ("1 cup broth + 1 tbsp vinegar", "For savory"),
            ("1 cup grape or apple juice", "For sweet")
        ]),
        .init(ingredient: "Lemon Juice", note: "Per 1 tbsp lemon juice.", options: [
            ("1 tbsp white vinegar", "For acidity"),
            ("1 tbsp lime juice", "1:1")
        ]),
        .init(ingredient: "Cocoa Powder", note: "Per 3 tbsp cocoa.", options: [
            ("1 oz unsweetened chocolate, reduce fat by 1 tbsp", "Melt in")
        ]),
        .init(ingredient: "Unsweetened Chocolate", note: "Per 1 oz.", options: [
            ("3 tbsp cocoa + 1 tbsp butter or oil", "")
        ]),
        .init(ingredient: "Cream Cheese", note: "Per 1 cup.", options: [
            ("1 cup blended cottage cheese", ""),
            ("1 cup thick Greek yogurt, strained", "")
        ]),
        .init(ingredient: "Mayonnaise", note: "Per 1 cup.", options: [
            ("1 cup plain Greek yogurt", "Tangier"),
            ("1 cup sour cream", "")
        ]),
        .init(ingredient: "Breadcrumbs", note: "Per 1 cup dry breadcrumbs.", options: [
            ("1 cup panko", "Crispier"),
            ("1 cup crushed crackers", ""),
            ("1 cup rolled oats, pulsed", "")
        ]),
        .init(ingredient: "Yeast", note: "Per 1 packet (2¼ tsp) active dry.", options: [
            ("2¼ tsp instant yeast", "Skip proofing step"),
            ("1 tbsp + ¾ tsp fresh yeast", "")
        ]),
        .init(ingredient: "Vanilla Extract", note: "Per 1 tsp.", options: [
            ("1 tsp maple syrup", "In a pinch"),
            ("seeds of ½ vanilla bean", ""),
            ("1 tsp almond extract (use ½)", "Stronger flavor")
        ]),
        .init(ingredient: "Cornmeal", note: "Per 1 cup.", options: [
            ("1 cup polenta", "Coarser"),
            ("1 cup grits", "")
        ]),
        .init(ingredient: "Ricotta", note: "Per 1 cup.", options: [
            ("1 cup cottage cheese, drained", ""),
            ("1 cup blended silken tofu", "Dairy-free")
        ]),
        .init(ingredient: "Half-and-Half", note: "Per 1 cup.", options: [
            ("¾ cup milk + ¼ cup heavy cream", ""),
            ("⅞ cup milk + 1 tbsp melted butter", "")
        ]),
        .init(ingredient: "Tomato Sauce", note: "Per 1 cup.", options: [
            ("½ cup tomato paste + ½ cup water", "Whisk smooth")
        ]),
        .init(ingredient: "Tomato Paste", note: "Per 1 tbsp.", options: [
            ("1 tbsp ketchup (reduce sugar elsewhere)", ""),
            ("2–3 tbsp tomato sauce, reduced", "")
        ]),
        .init(ingredient: "Molasses", note: "Per 1 cup.", options: [
            ("¾ cup brown sugar", "Reduce liquid slightly"),
            ("1 cup dark corn syrup", "")
        ]),
        .init(ingredient: "Corn Syrup", note: "Per 1 cup.", options: [
            ("1 cup sugar + ¼ cup water, simmered", ""),
            ("1 cup honey", "Flavor differs")
        ]),
        .init(ingredient: "Maple Syrup", note: "Per 1 cup.", options: [
            ("1 cup honey", "1:1"),
            ("¾ cup sugar + ¼ cup water", "")
        ]),
        .init(ingredient: "Shortening", note: "Per 1 cup.", options: [
            ("1 cup + 2 tbsp butter", "Adjust salt"),
            ("1 cup coconut oil", "Solid")
        ]),
        .init(ingredient: "Bread Flour", note: "Per 1 cup.", options: [
            ("1 cup all-purpose flour + 1 tsp vital wheat gluten", "Chewier crumb")
        ]),
        .init(ingredient: "Whole Wheat Flour", note: "Per 1 cup.", options: [
            ("1 cup all-purpose flour", "Lighter result"),
            ("½ cup whole wheat + ½ cup AP", "Balanced")
        ]),
        .init(ingredient: "Caster Sugar", note: "Per 1 cup.", options: [
            ("1 cup granulated sugar, pulsed briefly", "Blend until fine")
        ]),
        .init(ingredient: "Crème Fraîche", note: "Per 1 cup.", options: [
            ("1 cup sour cream", "Tangier"),
            ("1 cup mascarpone", "Richer")
        ]),
        .init(ingredient: "Evaporated Milk", note: "Per 1 cup.", options: [
            ("1 cup half-and-half", ""),
            ("1 cup milk, simmered to reduce by half", "")
        ]),
        .init(ingredient: "Condensed Milk", note: "Per 1 can (14 oz).", options: [
            ("1 cup nonfat dry milk + ⅔ cup sugar + ½ cup hot water", "Blend smooth")
        ]),
        .init(ingredient: "Pumpkin Purée", note: "Per 1 cup.", options: [
            ("1 cup mashed sweet potato", ""),
            ("1 cup butternut squash purée", "")
        ]),
        .init(ingredient: "Mascarpone", note: "Per 1 cup.", options: [
            ("8 oz cream cheese + 3 tbsp heavy cream + 1 tbsp butter", "Blend smooth")
        ]),
        .init(ingredient: "Buttermilk Powder", note: "Per 1 cup liquid buttermilk.", options: [
            ("4 tbsp powder + 1 cup water", "")
        ]),
        .init(ingredient: "Allspice", note: "Per 1 tsp.", options: [
            ("½ tsp cinnamon + ¼ tsp nutmeg + ¼ tsp cloves", "")
        ]),
        .init(ingredient: "Pumpkin Pie Spice", note: "Per 1 tsp.", options: [
            ("½ tsp cinnamon + ¼ tsp ginger + ⅛ tsp nutmeg + ⅛ tsp cloves", "")
        ]),
        .init(ingredient: "Italian Seasoning", note: "Per 1 tbsp.", options: [
            ("1 tsp each dried basil, oregano, thyme", "")
        ]),
        .init(ingredient: "Dijon Mustard", note: "Per 1 tbsp.", options: [
            ("1 tbsp yellow mustard + pinch of dry mustard", "")
        ]),
        .init(ingredient: "Soy Sauce", note: "Per 1 tbsp.", options: [
            ("1 tbsp tamari", "Gluten-free"),
            ("1 tbsp coconut aminos", "Lower sodium")
        ]),
        .init(ingredient: "Worcestershire Sauce", note: "Per 1 tbsp.", options: [
            ("1 tbsp soy sauce + pinch sugar + dash hot sauce", "")
        ]),
        .init(ingredient: "Rice Vinegar", note: "Per 1 tbsp.", options: [
            ("1 tbsp apple cider vinegar + pinch sugar", ""),
            ("1 tbsp white wine vinegar", "")
        ]),
        .init(ingredient: "Fresh Ginger", note: "Per 1 tbsp grated.", options: [
            ("¼ tsp ground ginger", "")
        ]),
        .init(ingredient: "Shallot", note: "Per 1 shallot.", options: [
            ("2 tbsp minced onion + pinch garlic", "")
        ]),
        .init(ingredient: "Buttermilk Ranch (dry)", note: "Per 1 tbsp.", options: [
            ("¼ tsp each garlic powder, onion powder, dried dill + ½ tsp parsley", "")
        ]),
        .init(ingredient: "Confectioners' Glaze", note: "Per 1 cup.", options: [
            ("1 cup powdered sugar + 2 tbsp milk", "Whisk to drizzle")
        ])
    ]

    // MARK: - Example recipes

    @MainActor
    static func seedRecipesIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<SavedRecipe>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let pancakes = SavedRecipe(
            title: "Fluffy Buttermilk Pancakes",
            baseServings: 4,
            notes: "Don't overmix — lumps are fine. Rest the batter 5 minutes."
        )
        pancakes.ingredients = lines([
            ("All-Purpose Flour", 1.5, .cup),
            ("Granulated Sugar", 2, .tablespoon),
            ("Baking Powder", 2, .teaspoon),
            ("Salt (table)", 0.5, .teaspoon),
            ("Buttermilk", 1.25, .cup),
            ("Melted Butter", 3, .tablespoon)
        ])

        let cookies = SavedRecipe(
            title: "Classic Chocolate Chip Cookies",
            baseServings: 24,
            notes: "Chill the dough 30 min for thicker cookies."
        )
        cookies.ingredients = lines([
            ("All-Purpose Flour", 2.25, .cup),
            ("Butter", 1, .cup),
            ("Brown Sugar (packed)", 0.75, .cup),
            ("Granulated Sugar", 0.75, .cup),
            ("Baking Soda", 1, .teaspoon),
            ("Chocolate Chips", 2, .cup)
        ])

        let soup = SavedRecipe(
            title: "Weeknight Tomato Soup",
            baseServings: 6,
            notes: "Blend smooth or leave rustic — your call."
        )
        soup.ingredients = lines([
            ("Olive Oil", 2, .tablespoon),
            ("Tomato Paste", 0.25, .cup),
            ("Water", 4, .cup),
            ("Heavy Cream", 0.5, .cup),
            ("Salt (table)", 1, .teaspoon)
        ])

        context.insert(pancakes)
        context.insert(cookies)
        context.insert(soup)
        try? context.save()
    }

    private static func lines(_ items: [(String, Double, MeasureUnit)]) -> [RecipeIngredient] {
        items.enumerated().map { idx, t in
            RecipeIngredient(name: t.0, quantity: t.1, unit: t.2, sortOrder: idx)
        }
    }
}
