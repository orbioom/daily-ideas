import Foundation
import SwiftData

/// Seeds realistic sample data on first launch, behind the "didSeed" flag.
enum SeedData {

    // MARK: Public API

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }

        for spec in pantrySpecs() {
            context.insert(PantryItem(name: spec.name,
                                      aisle: spec.aisle,
                                      inStock: spec.inStock))
        }

        let base = Date()
        for (offset, spec) in recipeSpecs().enumerated() {
            let recipe = Recipe(name: spec.name,
                                cuisine: spec.cuisine,
                                minutes: spec.minutes,
                                servings: spec.servings,
                                difficulty: spec.difficulty,
                                steps: spec.steps,
                                notes: spec.notes,
                                isFavorite: offset % 11 == 0,
                                dateAdded: base.addingTimeInterval(Double(-offset) * 3600))
            context.insert(recipe)
            for ing in spec.ingredients {
                let ri = RecipeIngredient(name: ing.0, amount: ing.1, optional: ing.2)
                ri.recipe = recipe
                recipe.ingredients.append(ri)
            }
        }

        try? context.save()
        didSeed = true
    }

    /// Wipe all recipes (cascading ingredients) and pantry items.
    static func clearAll(context: ModelContext) {
        if let recipes = try? context.fetch(FetchDescriptor<Recipe>()) {
            for r in recipes { context.delete(r) }
        }
        if let items = try? context.fetch(FetchDescriptor<PantryItem>()) {
            for i in items { context.delete(i) }
        }
        try? context.save()
    }

    /// The set of staple pantry items for the "Stock the basics" quick-add.
    static func basicsSpecs() -> [(name: String, aisle: Aisle)] {
        [
            ("Salt", .spices), ("Black Pepper", .spices), ("Olive Oil", .condiments),
            ("Butter", .dairy), ("Sugar", .pantryStaple), ("All-Purpose Flour", .pantryStaple),
            ("Garlic", .produce), ("Onion", .produce), ("Eggs", .dairy),
            ("Rice", .grains), ("Pasta", .grains), ("Soy Sauce", .condiments)
        ]
    }

    // MARK: Pantry

    private struct PantrySpec { let name: String; let aisle: Aisle; let inStock: Bool }

    private static func pantrySpecs() -> [PantrySpec] {
        func p(_ n: String, _ a: Aisle, _ s: Bool = true) -> PantrySpec { PantrySpec(name: n, aisle: a, inStock: s) }
        return [
            // Produce
            p("Onion", .produce), p("Garlic", .produce), p("Tomatoes", .produce),
            p("Potatoes", .produce), p("Carrots", .produce), p("Spinach", .produce, false),
            p("Bell Pepper", .produce), p("Lemon", .produce), p("Lime", .produce, false),
            p("Mushrooms", .produce, false), p("Avocado", .produce, false), p("Cilantro", .produce),
            p("Ginger", .produce), p("Scallions", .produce, false), p("Broccoli", .produce, false),
            // Meat & Fish
            p("Chicken Breast", .meat), p("Ground Beef", .meat), p("Bacon", .meat, false),
            p("Eggs", .dairy), p("Shrimp", .meat, false),
            // Dairy
            p("Milk", .dairy), p("Butter", .dairy), p("Parmesan", .dairy),
            p("Cheddar Cheese", .dairy, false), p("Greek Yogurt", .dairy, false), p("Cream", .dairy, false),
            // Pantry staples
            p("Olive Oil", .condiments), p("Salt", .spices), p("Black Pepper", .spices),
            p("Sugar", .pantryStaple), p("All-Purpose Flour", .pantryStaple), p("Canned Tomatoes", .pantryStaple),
            p("Chickpeas", .pantryStaple, false), p("Coconut Milk", .pantryStaple, false),
            // Grains
            p("Rice", .grains), p("Spaghetti", .grains), p("Tortillas", .bakery, false),
            // Condiments / spices
            p("Soy Sauce", .condiments), p("Cumin", .spices), p("Paprika", .spices),
            p("Chili Flakes", .spices), p("Honey", .condiments, false)
        ]
    }

    // MARK: Recipes

    private struct RecipeSpec {
        let name: String
        let cuisine: Cuisine
        let minutes: Int
        let servings: Int
        let difficulty: Difficulty
        let ingredients: [(String, String, Bool)]   // name, amount, optional
        let steps: [String]
        let notes: String
    }

    // swiftlint:disable:next function_body_length
    private static func recipeSpecs() -> [RecipeSpec] {
        var list: [RecipeSpec] = []
        func r(_ name: String, _ cuisine: Cuisine, _ min: Int, _ serv: Int, _ diff: Difficulty,
               _ ing: [(String, String, Bool)], _ steps: [String], _ notes: String = "") {
            list.append(RecipeSpec(name: name, cuisine: cuisine, minutes: min, servings: serv,
                                   difficulty: diff, ingredients: ing, steps: steps, notes: notes))
        }

        r("Spaghetti Aglio e Olio", .italian, 20, 2, .easy,
          [("Spaghetti", "200 g", false), ("Garlic", "4 cloves", false), ("Olive Oil", "1/3 cup", false),
           ("Chili Flakes", "1 tsp", true), ("Parsley", "2 tbsp", true), ("Parmesan", "1/4 cup", true)],
          ["Boil spaghetti in salted water until al dente.",
           "Gently sizzle sliced garlic in olive oil until golden.",
           "Toss drained pasta with the oil, chili flakes and a splash of pasta water.",
           "Finish with parsley and parmesan."],
          "The classic midnight pasta.")

        r("Classic Margherita Pizza", .italian, 40, 2, .medium,
          [("All-Purpose Flour", "2 cups", false), ("Canned Tomatoes", "1 cup", false),
           ("Mozzarella", "150 g", false), ("Olive Oil", "2 tbsp", false), ("Basil", "8 leaves", true),
           ("Salt", "1 tsp", false)],
          ["Mix flour, water, salt and a little oil into a dough; rest 30 min.",
           "Stretch dough, spread crushed tomatoes.",
           "Top with torn mozzarella.",
           "Bake at highest heat until blistered, finish with basil."],
          "Keep toppings minimal.")

        r("Spaghetti Carbonara", .italian, 25, 2, .medium,
          [("Spaghetti", "200 g", false), ("Eggs", "3", false), ("Parmesan", "1/2 cup", false),
           ("Bacon", "120 g", false), ("Black Pepper", "1 tsp", false)],
          ["Cook spaghetti in salted water.",
           "Crisp chopped bacon in a pan.",
           "Whisk eggs with parmesan and lots of pepper.",
           "Toss hot pasta off-heat with bacon then the egg mix, loosening with pasta water."],
          "No cream — the egg makes the sauce.")

        r("Tomato Basil Pasta", .italian, 25, 4, .easy,
          [("Spaghetti", "400 g", false), ("Canned Tomatoes", "2 cups", false), ("Garlic", "3 cloves", false),
           ("Olive Oil", "3 tbsp", false), ("Basil", "handful", true), ("Onion", "1", false)],
          ["Soften onion and garlic in olive oil.",
           "Add tomatoes and simmer 15 minutes.",
           "Toss with cooked spaghetti and basil."])

        r("Creamy Mushroom Risotto", .italian, 40, 4, .hard,
          [("Rice", "1.5 cups", false), ("Mushrooms", "300 g", false), ("Onion", "1", false),
           ("Parmesan", "1/2 cup", false), ("Butter", "3 tbsp", false), ("Cream", "1/4 cup", true)],
          ["Sauté mushrooms; set aside.",
           "Soften onion in butter, add rice, toast briefly.",
           "Add warm stock a ladle at a time, stirring, until creamy.",
           "Fold in mushrooms, parmesan and a touch of cream."])

        r("Eggplant Parmesan", .italian, 60, 4, .hard,
          [("Eggplant", "2", false), ("Canned Tomatoes", "2 cups", false), ("Mozzarella", "200 g", false),
           ("Parmesan", "1/2 cup", false), ("All-Purpose Flour", "1/2 cup", false), ("Eggs", "2", false)],
          ["Slice and salt eggplant, pat dry.",
           "Dredge in flour and egg, fry until golden.",
           "Layer with tomato sauce and cheeses.",
           "Bake until bubbling."])

        r("Chicken Quesadilla", .mexican, 20, 2, .easy,
          [("Tortillas", "4", false), ("Chicken Breast", "300 g", false), ("Cheddar Cheese", "1.5 cups", false),
           ("Bell Pepper", "1", true), ("Onion", "1/2", true)],
          ["Cook and shred seasoned chicken.",
           "Fill tortillas with chicken, cheese and peppers.",
           "Griddle until crisp and the cheese melts.",
           "Slice into wedges."])

        r("Beef Tacos", .mexican, 25, 4, .easy,
          [("Ground Beef", "500 g", false), ("Tortillas", "8", false), ("Onion", "1", false),
           ("Cumin", "1 tsp", false), ("Paprika", "1 tsp", false), ("Cilantro", "1/4 cup", true),
           ("Lime", "1", true)],
          ["Brown beef with onion.",
           "Season with cumin and paprika.",
           "Warm tortillas.",
           "Fill and top with cilantro and lime."])

        r("Guacamole", .mexican, 10, 4, .easy,
          [("Avocado", "3", false), ("Lime", "1", false), ("Onion", "1/2", false),
           ("Cilantro", "1/4 cup", true), ("Salt", "to taste", false)],
          ["Mash avocados.",
           "Stir in lime juice, finely diced onion and cilantro.",
           "Season with salt."])

        r("Black Bean Soup", .mexican, 35, 4, .easy,
          [("Chickpeas", "2 cups", false), ("Onion", "1", false), ("Garlic", "3 cloves", false),
           ("Cumin", "1 tsp", false), ("Canned Tomatoes", "1 cup", false), ("Lime", "1", true)],
          ["Soften onion and garlic.",
           "Add beans, tomatoes, cumin and water.",
           "Simmer 25 minutes, blend half for body.",
           "Finish with lime."])

        r("Huevos Rancheros", .mexican, 20, 2, .easy,
          [("Eggs", "4", false), ("Tortillas", "4", false), ("Canned Tomatoes", "1 cup", false),
           ("Onion", "1/2", false), ("Chili Flakes", "1/2 tsp", true)],
          ["Simmer tomatoes with onion and chili into a salsa.",
           "Fry the eggs.",
           "Warm tortillas, top with salsa and eggs."])

        r("Chicken Stir-Fry", .asian, 20, 2, .easy,
          [("Chicken Breast", "300 g", false), ("Soy Sauce", "3 tbsp", false), ("Garlic", "2 cloves", false),
           ("Ginger", "1 tbsp", false), ("Broccoli", "2 cups", false), ("Rice", "1 cup", true),
           ("Scallions", "2", true)],
          ["Slice and sear chicken.",
           "Add garlic, ginger and broccoli, stir-fry.",
           "Splash in soy sauce.",
           "Serve over rice with scallions."])

        r("Fried Rice", .asian, 20, 2, .easy,
          [("Rice", "3 cups cooked", false), ("Eggs", "2", false), ("Soy Sauce", "2 tbsp", false),
           ("Carrots", "1", false), ("Scallions", "2", true), ("Garlic", "2 cloves", false)],
          ["Scramble eggs, set aside.",
           "Stir-fry diced carrots and garlic.",
           "Add cold rice and soy sauce, toss over high heat.",
           "Fold in eggs and scallions."],
          "Day-old rice works best.")

        r("Vegetable Lo Mein", .asian, 25, 3, .medium,
          [("Spaghetti", "300 g", false), ("Soy Sauce", "3 tbsp", false), ("Carrots", "2", false),
           ("Bell Pepper", "1", false), ("Garlic", "2 cloves", false), ("Ginger", "1 tbsp", true)],
          ["Boil noodles.",
           "Stir-fry vegetables with garlic and ginger.",
           "Add noodles and soy sauce, toss to coat."])

        r("Shrimp Pad Thai", .asian, 30, 2, .medium,
          [("Shrimp", "250 g", false), ("Spaghetti", "200 g", false), ("Eggs", "2", false),
           ("Soy Sauce", "2 tbsp", false), ("Lime", "1", false), ("Scallions", "2", true),
           ("Sugar", "1 tbsp", false)],
          ["Soak noodles until pliable.",
           "Sear shrimp, push aside and scramble eggs.",
           "Add noodles with soy, sugar and lime.",
           "Toss, finish with scallions."])

        r("Egg Drop Soup", .asian, 15, 2, .easy,
          [("Eggs", "2", false), ("Scallions", "2", true), ("Ginger", "1 tsp", true),
           ("Soy Sauce", "1 tbsp", false), ("Salt", "to taste", false)],
          ["Bring seasoned stock to a simmer.",
           "Slowly stream in beaten eggs while stirring.",
           "Finish with scallions."])

        r("Butter Chicken", .indian, 45, 4, .medium,
          [("Chicken Breast", "600 g", false), ("Canned Tomatoes", "2 cups", false), ("Cream", "1/2 cup", false),
           ("Butter", "3 tbsp", false), ("Garlic", "4 cloves", false), ("Ginger", "1 tbsp", false),
           ("Paprika", "1 tbsp", false)],
          ["Sear marinated chicken.",
           "Cook garlic, ginger and paprika in butter.",
           "Add tomatoes, simmer, then blend smooth.",
           "Return chicken, stir in cream."])

        r("Chana Masala", .indian, 35, 4, .easy,
          [("Chickpeas", "2 cups", false), ("Onion", "1", false), ("Canned Tomatoes", "1.5 cups", false),
           ("Garlic", "3 cloves", false), ("Ginger", "1 tbsp", false), ("Cumin", "1 tsp", false),
           ("Paprika", "1 tsp", false)],
          ["Sauté onion until golden.",
           "Add garlic, ginger and spices.",
           "Stir in tomatoes and chickpeas.",
           "Simmer 20 minutes."])

        r("Coconut Chicken Curry", .indian, 40, 4, .medium,
          [("Chicken Breast", "600 g", false), ("Coconut Milk", "1 can", false), ("Onion", "1", false),
           ("Garlic", "3 cloves", false), ("Ginger", "1 tbsp", false), ("Paprika", "1 tbsp", false),
           ("Cilantro", "handful", true)],
          ["Brown chicken pieces.",
           "Soften onion, garlic and ginger with spices.",
           "Add coconut milk and chicken, simmer.",
           "Finish with cilantro."])

        r("Vegetable Korma", .indian, 35, 4, .medium,
          [("Potatoes", "2", false), ("Carrots", "2", false), ("Coconut Milk", "1 can", false),
           ("Onion", "1", false), ("Garlic", "3 cloves", false), ("Cumin", "1 tsp", false)],
          ["Sauté onion and garlic.",
           "Add cumin, then potatoes and carrots.",
           "Pour in coconut milk and simmer until tender."])

        r("Greek Salad", .mediterranean, 15, 4, .easy,
          [("Tomatoes", "3", false), ("Cucumber", "1", false), ("Feta", "150 g", false),
           ("Onion", "1/2", false), ("Olive Oil", "3 tbsp", false), ("Lemon", "1", true)],
          ["Chop tomatoes, cucumber and onion.",
           "Crumble over feta.",
           "Dress with olive oil and lemon."])

        r("Hummus", .mediterranean, 10, 6, .easy,
          [("Chickpeas", "2 cups", false), ("Garlic", "2 cloves", false), ("Lemon", "1", false),
           ("Olive Oil", "1/4 cup", false), ("Cumin", "1/2 tsp", true)],
          ["Blend chickpeas with garlic and lemon.",
           "Stream in olive oil until smooth.",
           "Season and dust with cumin."])

        r("Shakshuka", .mediterranean, 30, 2, .easy,
          [("Eggs", "4", false), ("Canned Tomatoes", "2 cups", false), ("Bell Pepper", "1", false),
           ("Onion", "1", false), ("Garlic", "2 cloves", false), ("Paprika", "1 tsp", false),
           ("Cilantro", "handful", true)],
          ["Soften onion, pepper and garlic.",
           "Add tomatoes and paprika, simmer.",
           "Make wells and crack in eggs.",
           "Cover until eggs set."])

        r("Falafel Bowl", .middleEastern, 35, 4, .medium,
          [("Chickpeas", "2 cups", false), ("Garlic", "3 cloves", false), ("Cilantro", "1/2 cup", false),
           ("Cumin", "1 tsp", false), ("All-Purpose Flour", "2 tbsp", false), ("Onion", "1/2", false)],
          ["Blend chickpeas with herbs, garlic, onion and cumin.",
           "Bind with flour, form patties.",
           "Fry until crisp.",
           "Serve in a bowl with greens."])

        r("Lentil Soup", .middleEastern, 40, 4, .easy,
          [("Chickpeas", "1.5 cups", false), ("Carrots", "2", false), ("Onion", "1", false),
           ("Garlic", "3 cloves", false), ("Cumin", "1 tsp", false), ("Canned Tomatoes", "1 cup", true)],
          ["Sauté onion, carrot and garlic.",
           "Add lentils, cumin and water.",
           "Simmer until soft, blend partly if you like."])

        r("Classic Cheeseburger", .american, 20, 2, .easy,
          [("Ground Beef", "300 g", false), ("Cheddar Cheese", "2 slices", false), ("Onion", "1/2", true),
           ("Tomatoes", "1", true), ("Salt", "to taste", false), ("Black Pepper", "to taste", false)],
          ["Form seasoned patties.",
           "Sear hard on each side.",
           "Melt cheese on top.",
           "Build with your toppings."])

        r("Mac and Cheese", .american, 30, 4, .easy,
          [("Spaghetti", "400 g", false), ("Cheddar Cheese", "2 cups", false), ("Milk", "2 cups", false),
           ("Butter", "3 tbsp", false), ("All-Purpose Flour", "3 tbsp", false)],
          ["Cook the pasta.",
           "Make a roux with butter and flour.",
           "Whisk in milk, then cheese until smooth.",
           "Fold through pasta."])

        r("Loaded Baked Potatoes", .american, 60, 4, .easy,
          [("Potatoes", "4", false), ("Cheddar Cheese", "1 cup", false), ("Bacon", "4 strips", true),
           ("Scallions", "2", true), ("Butter", "2 tbsp", false)],
          ["Bake potatoes until tender.",
           "Split and fluff with butter.",
           "Load with cheese, bacon and scallions."])

        r("Buffalo Chicken Wraps", .american, 25, 2, .easy,
          [("Chicken Breast", "300 g", false), ("Tortillas", "2", false), ("Cheddar Cheese", "1/2 cup", false),
           ("Chili Flakes", "1 tsp", false), ("Butter", "2 tbsp", false)],
          ["Cook and shred chicken.",
           "Toss in butter and chili.",
           "Wrap with cheese and greens."])

        r("Sausage and Peppers", .american, 30, 4, .easy,
          [("Bell Pepper", "2", false), ("Onion", "1", false), ("Bacon", "4 strips", false),
           ("Garlic", "2 cloves", false), ("Olive Oil", "2 tbsp", false)],
          ["Sear sausage pieces.",
           "Add peppers, onion and garlic.",
           "Cook until soft and caramelized."])

        r("French Omelette", .french, 10, 1, .medium,
          [("Eggs", "3", false), ("Butter", "1 tbsp", false), ("Cheddar Cheese", "1/4 cup", true),
           ("Salt", "to taste", false)],
          ["Beat eggs with salt.",
           "Melt butter in a non-stick pan.",
           "Stir gently, then roll the omelette while still soft."])

        r("Ratatouille", .french, 50, 4, .medium,
          [("Eggplant", "1", false), ("Bell Pepper", "2", false), ("Tomatoes", "4", false),
           ("Onion", "1", false), ("Garlic", "3 cloves", false), ("Olive Oil", "1/4 cup", false)],
          ["Sauté onion and garlic.",
           "Add diced vegetables.",
           "Simmer low and slow until silky."])

        r("Quiche Lorraine", .french, 55, 6, .hard,
          [("Eggs", "4", false), ("Cream", "1 cup", false), ("Bacon", "150 g", false),
           ("Cheddar Cheese", "1 cup", false), ("All-Purpose Flour", "1.5 cups", false), ("Butter", "1/2 cup", false)],
          ["Make and blind-bake a pastry shell.",
           "Crisp the bacon.",
           "Whisk eggs with cream and cheese.",
           "Pour over bacon and bake until set."])

        r("Croque Monsieur", .french, 20, 2, .easy,
          [("Bread", "4 slices", false), ("Cheddar Cheese", "1 cup", false), ("Butter", "2 tbsp", false),
           ("Milk", "1/2 cup", false), ("All-Purpose Flour", "1 tbsp", false)],
          ["Make a quick cheese béchamel.",
           "Build sandwiches with ham and cheese.",
           "Top with sauce and grill until golden."])

        r("Fluffy Pancakes", .breakfast, 20, 4, .easy,
          [("All-Purpose Flour", "1.5 cups", false), ("Milk", "1.25 cups", false), ("Eggs", "1", false),
           ("Sugar", "2 tbsp", false), ("Butter", "2 tbsp", false), ("Honey", "to serve", true)],
          ["Whisk dry then wet ingredients.",
           "Rest the batter briefly.",
           "Cook on a buttered griddle until bubbles pop.",
           "Serve with honey."])

        r("Veggie Scramble", .breakfast, 15, 2, .easy,
          [("Eggs", "4", false), ("Bell Pepper", "1", false), ("Spinach", "1 cup", false),
           ("Onion", "1/2", false), ("Cheddar Cheese", "1/4 cup", true), ("Butter", "1 tbsp", false)],
          ["Soften onion and pepper.",
           "Add spinach to wilt.",
           "Pour in eggs and stir to soft curds.",
           "Finish with cheese."])

        r("Avocado Toast", .breakfast, 10, 1, .easy,
          [("Bread", "2 slices", false), ("Avocado", "1", false), ("Lemon", "1/2", false),
           ("Chili Flakes", "pinch", true), ("Eggs", "1", true)],
          ["Toast the bread.",
           "Mash avocado with lemon and salt.",
           "Spread and top with chili flakes."])

        r("French Toast", .breakfast, 15, 2, .easy,
          [("Bread", "4 slices", false), ("Eggs", "2", false), ("Milk", "1/2 cup", false),
           ("Sugar", "1 tbsp", false), ("Butter", "2 tbsp", false), ("Honey", "to serve", true)],
          ["Whisk eggs, milk and sugar.",
           "Soak bread slices.",
           "Fry in butter until golden.",
           "Drizzle with honey."])

        r("Banana Oat Smoothie", .breakfast, 5, 2, .easy,
          [("Milk", "1.5 cups", false), ("Greek Yogurt", "1/2 cup", false), ("Honey", "1 tbsp", true),
           ("Banana", "2", false)],
          ["Add everything to a blender.",
           "Blend until smooth."])

        r("Chicken Noodle Soup", .american, 40, 4, .easy,
          [("Chicken Breast", "300 g", false), ("Carrots", "2", false), ("Onion", "1", false),
           ("Spaghetti", "200 g", false), ("Garlic", "2 cloves", false), ("Cilantro", "handful", true)],
          ["Simmer chicken with aromatics.",
           "Shred chicken, return to the pot.",
           "Cook noodles in the broth.",
           "Season and serve."])

        r("Tomato Soup", .american, 30, 4, .easy,
          [("Canned Tomatoes", "3 cups", false), ("Onion", "1", false), ("Garlic", "3 cloves", false),
           ("Cream", "1/4 cup", true), ("Butter", "2 tbsp", false), ("Basil", "handful", true)],
          ["Soften onion and garlic in butter.",
           "Add tomatoes, simmer 20 minutes.",
           "Blend smooth, swirl in cream and basil."])

        r("Garlic Butter Shrimp", .american, 15, 2, .easy,
          [("Shrimp", "350 g", false), ("Garlic", "4 cloves", false), ("Butter", "3 tbsp", false),
           ("Lemon", "1", false), ("Chili Flakes", "1/2 tsp", true)],
          ["Melt butter, add garlic.",
           "Sear shrimp until pink.",
           "Finish with lemon and chili."])

        r("Stuffed Bell Peppers", .mediterranean, 50, 4, .medium,
          [("Bell Pepper", "4", false), ("Ground Beef", "400 g", false), ("Rice", "1 cup", false),
           ("Canned Tomatoes", "1 cup", false), ("Onion", "1", false), ("Cheddar Cheese", "1 cup", true)],
          ["Brown beef with onion.",
           "Stir in cooked rice and tomatoes.",
           "Stuff halved peppers.",
           "Bake until tender, top with cheese."])

        r("Shepherd's Pie", .american, 60, 6, .medium,
          [("Ground Beef", "600 g", false), ("Potatoes", "5", false), ("Carrots", "2", false),
           ("Onion", "1", false), ("Butter", "3 tbsp", false), ("Milk", "1/2 cup", false)],
          ["Brown beef with onion and carrot.",
           "Boil and mash potatoes with butter and milk.",
           "Top the meat with mash.",
           "Bake until golden."])

        r("Chicken Fajitas", .mexican, 25, 4, .easy,
          [("Chicken Breast", "500 g", false), ("Bell Pepper", "2", false), ("Onion", "1", false),
           ("Tortillas", "8", false), ("Cumin", "1 tsp", false), ("Paprika", "1 tsp", false),
           ("Lime", "1", true)],
          ["Slice chicken and toss with spices.",
           "Sear hot with peppers and onion.",
           "Warm tortillas and serve with lime."])

        r("Caprese Salad", .italian, 10, 2, .easy,
          [("Tomatoes", "3", false), ("Mozzarella", "200 g", false), ("Basil", "handful", false),
           ("Olive Oil", "2 tbsp", false), ("Salt", "to taste", false)],
          ["Slice tomatoes and mozzarella.",
           "Layer with basil.",
           "Drizzle with oil and season."])

        r("Minestrone", .italian, 45, 6, .easy,
          [("Carrots", "2", false), ("Onion", "1", false), ("Canned Tomatoes", "2 cups", false),
           ("Chickpeas", "1 cup", false), ("Spaghetti", "100 g", false), ("Garlic", "3 cloves", false),
           ("Spinach", "1 cup", true)],
          ["Sauté onion, carrot and garlic.",
           "Add tomatoes, beans and water.",
           "Simmer, add pasta near the end.",
           "Wilt in spinach."])

        r("Honey Garlic Chicken", .asian, 30, 4, .easy,
          [("Chicken Breast", "600 g", false), ("Honey", "1/4 cup", false), ("Garlic", "4 cloves", false),
           ("Soy Sauce", "3 tbsp", false), ("Rice", "2 cups", true)],
          ["Sear chicken pieces.",
           "Add garlic, honey and soy.",
           "Simmer to a glaze.",
           "Serve over rice."])

        r("Teriyaki Salmon", .asian, 25, 2, .medium,
          [("Salmon", "2 fillets", false), ("Soy Sauce", "3 tbsp", false), ("Honey", "2 tbsp", false),
           ("Ginger", "1 tbsp", false), ("Garlic", "2 cloves", false), ("Scallions", "2", true)],
          ["Mix soy, honey, ginger and garlic.",
           "Sear salmon skin-side down.",
           "Add sauce and glaze.",
           "Top with scallions."])

        r("Caesar Salad", .american, 15, 2, .easy,
          [("Lettuce", "1 head", false), ("Parmesan", "1/2 cup", false), ("Bread", "2 slices", false),
           ("Garlic", "1 clove", false), ("Olive Oil", "3 tbsp", false), ("Lemon", "1", true)],
          ["Toast bread cubes with garlic oil for croutons.",
           "Toss lettuce with dressing.",
           "Add parmesan and croutons."])

        r("Potato Leek Soup", .french, 40, 4, .easy,
          [("Potatoes", "4", false), ("Onion", "1", false), ("Butter", "3 tbsp", false),
           ("Cream", "1/4 cup", true), ("Garlic", "2 cloves", false)],
          ["Soften onion and garlic in butter.",
           "Add potatoes and water, simmer until soft.",
           "Blend smooth, stir in cream."])

        r("Beef and Broccoli", .asian, 30, 4, .medium,
          [("Ground Beef", "500 g", false), ("Broccoli", "3 cups", false), ("Soy Sauce", "1/4 cup", false),
           ("Garlic", "3 cloves", false), ("Ginger", "1 tbsp", false), ("Rice", "2 cups", true)],
          ["Sear beef slices.",
           "Add broccoli, garlic and ginger.",
           "Pour in soy sauce and toss.",
           "Serve over rice."])

        r("Chocolate Mug Cake", .dessert, 5, 1, .easy,
          [("All-Purpose Flour", "4 tbsp", false), ("Sugar", "3 tbsp", false), ("Milk", "3 tbsp", false),
           ("Butter", "2 tbsp", false), ("Cocoa Powder", "2 tbsp", false)],
          ["Stir everything in a mug.",
           "Microwave about 90 seconds.",
           "Let cool a minute before eating."])

        r("Classic Pancakes Deluxe", .dessert, 25, 4, .easy,
          [("All-Purpose Flour", "2 cups", false), ("Sugar", "1/4 cup", false), ("Milk", "1.5 cups", false),
           ("Eggs", "2", false), ("Butter", "1/4 cup", false), ("Honey", "to serve", true)],
          ["Combine dry and wet separately, then fold.",
           "Cook on a buttered pan.",
           "Stack and drizzle with honey."])

        r("Apple Crumble", .dessert, 50, 6, .medium,
          [("Apple", "5", false), ("All-Purpose Flour", "1 cup", false), ("Sugar", "3/4 cup", false),
           ("Butter", "1/2 cup", false), ("Cinnamon", "1 tsp", true)],
          ["Toss sliced apples with sugar and cinnamon.",
           "Rub flour, butter and sugar into crumbs.",
           "Top apples and bake until golden."])

        r("Banana Bread", .dessert, 60, 8, .easy,
          [("Banana", "3", false), ("All-Purpose Flour", "1.5 cups", false), ("Sugar", "3/4 cup", false),
           ("Eggs", "2", false), ("Butter", "1/2 cup", false)],
          ["Mash bananas.",
           "Mix with melted butter, sugar and eggs.",
           "Fold in flour.",
           "Bake until a skewer comes out clean."])

        return list
    }
}
