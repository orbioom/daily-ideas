import Foundation
import SwiftData

/// Seeds the recipe library and pantry staples on first launch.
enum SeedData {
    /// Ingredient spec used by the compact seed table.
    private struct Ing {
        let name: String
        let qty: Double
        let unit: String
        let aisle: Aisle
        let staple: Bool
        init(_ name: String, _ qty: Double, _ unit: String, _ aisle: Aisle, staple: Bool = false) {
            self.name = name; self.qty = qty; self.unit = unit; self.aisle = aisle; self.staple = staple
        }
    }

    private struct Spec {
        let name: String
        let summary: String
        let servings: Int
        let prep: Int
        let cook: Int
        let effort: Effort
        let tags: [String]
        let steps: [String]
        let ings: [Ing]
    }

    @MainActor
    static func loadIfNeeded(into context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        guard count == 0 else { return }

        for spec in specs {
            let recipe = Recipe(
                name: spec.name,
                summary: spec.summary,
                servings: spec.servings,
                prepMinutes: spec.prep,
                cookMinutes: spec.cook,
                effort: spec.effort,
                tags: spec.tags,
                steps: spec.steps
            )
            context.insert(recipe)
            for ing in spec.ings {
                let ingredient = Ingredient(
                    name: ing.name,
                    quantity: ing.qty,
                    unit: ing.unit,
                    aisle: ing.aisle,
                    isStaple: ing.staple
                )
                ingredient.recipe = recipe
                context.insert(ingredient)
            }
        }

        for (name, aisle) in staples {
            context.insert(PantryStaple(name: name, aisle: aisle, haveOnHand: true))
        }

        // Ensure settings exist.
        _ = PersistenceController.settings(in: context)
        try? context.save()
    }

    private static let staples: [(String, Aisle)] = [
        ("Salt", .spices), ("Black pepper", .spices), ("Olive oil", .spices),
        ("Vegetable oil", .spices), ("Butter", .dairyEggs), ("All-purpose flour", .pantry),
        ("Sugar", .pantry), ("Garlic", .produce), ("Onion", .produce),
        ("Soy sauce", .pantry), ("Rice", .pantry), ("Pasta", .pantry)
    ]

    // MARK: - Recipe table (33 recipes)

    private static let specs: [Spec] = [
        Spec(name: "Sheet-Pan Chicken & Veg", summary: "One pan, golden chicken thighs over roasted vegetables.",
             servings: 4, prep: 15, cook: 35, effort: .easy, tags: ["Chicken", "One-Pan", "Gluten-Free"],
             steps: ["Heat oven to 425°F.", "Toss vegetables with oil, salt and pepper on a sheet pan.",
                     "Nestle chicken thighs on top and season.", "Roast 35 minutes until chicken reaches 165°F.", "Rest 5 minutes and serve."],
             ings: [Ing("Chicken thighs", 8, "pieces", .meatSeafood), Ing("Baby potatoes", 1.5, "lb", .produce),
                    Ing("Carrots", 4, "", .produce), Ing("Red onion", 1, "", .produce),
                    Ing("Olive oil", 3, "tbsp", .spices, staple: true), Ing("Salt", 1, "tsp", .spices, staple: true),
                    Ing("Black pepper", 0.5, "tsp", .spices, staple: true), Ing("Paprika", 1, "tsp", .spices)]),

        Spec(name: "Weeknight Spaghetti Bolognese", summary: "Rich, simmered meat sauce over spaghetti.",
             servings: 4, prep: 15, cook: 40, effort: .medium, tags: ["Beef", "Pasta", "Italian"],
             steps: ["Brown beef in a large pot, breaking it up.", "Add onion, carrot and garlic; cook until soft.",
                     "Stir in tomatoes and herbs; simmer 30 minutes.", "Cook spaghetti to package directions.",
                     "Toss pasta with sauce and top with parmesan."],
             ings: [Ing("Ground beef", 1, "lb", .meatSeafood), Ing("Spaghetti", 12, "oz", .pantry, staple: true),
                    Ing("Crushed tomatoes", 28, "oz", .pantry), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Carrot", 1, "", .produce), Ing("Garlic", 3, "cloves", .produce, staple: true),
                    Ing("Parmesan", 0.5, "cup", .dairyEggs), Ing("Olive oil", 2, "tbsp", .spices, staple: true)]),

        Spec(name: "Black Bean Tacos", summary: "Smoky black beans, crunchy slaw, lots of lime.",
             servings: 4, prep: 15, cook: 10, effort: .easy, tags: ["Vegetarian", "Mexican", "Fast"],
             steps: ["Warm beans with cumin and a splash of water.", "Mash lightly to thicken.",
                     "Char tortillas over a flame or in a dry pan.", "Fill with beans, slaw, avocado and lime."],
             ings: [Ing("Black beans", 2, "cans", .pantry), Ing("Corn tortillas", 8, "", .bakery),
                    Ing("Cabbage", 0.25, "head", .produce), Ing("Avocado", 1, "", .produce),
                    Ing("Lime", 2, "", .produce), Ing("Cumin", 1, "tsp", .spices), Ing("Cilantro", 0.5, "bunch", .produce)]),

        Spec(name: "Lemon Garlic Salmon", summary: "Bright pan-seared salmon with a quick lemon butter.",
             servings: 2, prep: 5, cook: 12, effort: .easy, tags: ["Fish", "Fast", "Gluten-Free"],
             steps: ["Pat salmon dry and season.", "Sear skin-side down 5 minutes.", "Flip, add butter, garlic and lemon.",
                     "Spoon butter over fish 2 minutes more."],
             ings: [Ing("Salmon fillets", 2, "", .meatSeafood), Ing("Butter", 2, "tbsp", .dairyEggs, staple: true),
                    Ing("Garlic", 2, "cloves", .produce, staple: true), Ing("Lemon", 1, "", .produce),
                    Ing("Salt", 0.5, "tsp", .spices, staple: true), Ing("Parsley", 2, "tbsp", .produce)]),

        Spec(name: "Veggie Stir-Fry", summary: "Crisp vegetables in a glossy ginger-soy sauce.",
             servings: 4, prep: 15, cook: 12, effort: .easy, tags: ["Vegetarian", "Asian", "Fast"],
             steps: ["Whisk sauce ingredients.", "Stir-fry hard vegetables first over high heat.",
                     "Add softer vegetables and sauce.", "Toss until glossy; serve over rice."],
             ings: [Ing("Broccoli", 1, "head", .produce), Ing("Bell pepper", 2, "", .produce),
                    Ing("Snap peas", 2, "cups", .produce), Ing("Carrot", 2, "", .produce),
                    Ing("Soy sauce", 3, "tbsp", .pantry, staple: true), Ing("Ginger", 1, "tbsp", .produce),
                    Ing("Garlic", 2, "cloves", .produce, staple: true), Ing("Rice", 2, "cups", .pantry, staple: true)]),

        Spec(name: "Margherita Flatbread", summary: "Crisp flatbread, tomato, mozzarella, basil.",
             servings: 2, prep: 10, cook: 12, effort: .easy, tags: ["Vegetarian", "Italian", "Fast"],
             steps: ["Heat oven to 450°F.", "Spread sauce over flatbreads.", "Top with mozzarella.",
                     "Bake 10–12 minutes; finish with basil and oil."],
             ings: [Ing("Flatbread", 2, "", .bakery), Ing("Tomato sauce", 0.5, "cup", .pantry),
                    Ing("Fresh mozzarella", 8, "oz", .dairyEggs), Ing("Basil", 0.5, "cup", .produce),
                    Ing("Olive oil", 1, "tbsp", .spices, staple: true)]),

        Spec(name: "Chicken Caesar Bowls", summary: "Crisp romaine, grilled chicken, creamy Caesar.",
             servings: 4, prep: 20, cook: 12, effort: .easy, tags: ["Chicken", "Salad", "Lunch"],
             steps: ["Season and grill chicken; slice.", "Chop romaine and toss with dressing.",
                     "Add croutons and parmesan.", "Top with sliced chicken."],
             ings: [Ing("Chicken breast", 2, "", .meatSeafood), Ing("Romaine", 2, "heads", .produce),
                    Ing("Caesar dressing", 0.5, "cup", .pantry), Ing("Croutons", 1, "cup", .bakery),
                    Ing("Parmesan", 0.5, "cup", .dairyEggs)]),

        Spec(name: "Thai Red Curry", summary: "Coconut curry with vegetables and tofu.",
             servings: 4, prep: 15, cook: 20, effort: .medium, tags: ["Vegetarian", "Thai", "Spicy"],
             steps: ["Fry curry paste in oil until fragrant.", "Add coconut milk and bring to a simmer.",
                     "Add tofu and vegetables; simmer 12 minutes.", "Finish with lime and serve over rice."],
             ings: [Ing("Red curry paste", 3, "tbsp", .pantry), Ing("Coconut milk", 2, "cans", .pantry),
                    Ing("Firm tofu", 14, "oz", .dairyEggs), Ing("Bell pepper", 1, "", .produce),
                    Ing("Zucchini", 1, "", .produce), Ing("Lime", 1, "", .produce), Ing("Rice", 2, "cups", .pantry, staple: true)]),

        Spec(name: "Turkey Chili", summary: "Hearty turkey and bean chili, freezer-friendly.",
             servings: 6, prep: 15, cook: 40, effort: .medium, tags: ["Turkey", "Soup", "Meal-Prep"],
             steps: ["Brown turkey with onion.", "Add spices and cook 1 minute.",
                     "Stir in tomatoes, beans and broth.", "Simmer 35 minutes; top with cheese."],
             ings: [Ing("Ground turkey", 1, "lb", .meatSeafood), Ing("Kidney beans", 2, "cans", .pantry),
                    Ing("Diced tomatoes", 28, "oz", .pantry), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Chili powder", 2, "tbsp", .spices), Ing("Chicken broth", 2, "cups", .pantry),
                    Ing("Cheddar", 1, "cup", .dairyEggs)]),

        Spec(name: "Greek Chicken Pita", summary: "Lemon-oregano chicken with tzatziki in warm pita.",
             servings: 4, prep: 20, cook: 12, effort: .medium, tags: ["Chicken", "Greek", "Lunch"],
             steps: ["Marinate chicken in lemon, oil and oregano.", "Grill and slice.",
                     "Warm pitas.", "Fill with chicken, tomato, onion and tzatziki."],
             ings: [Ing("Chicken thighs", 1, "lb", .meatSeafood), Ing("Pita bread", 4, "", .bakery),
                    Ing("Tzatziki", 1, "cup", .dairyEggs), Ing("Tomato", 2, "", .produce),
                    Ing("Red onion", 0.5, "", .produce), Ing("Lemon", 1, "", .produce),
                    Ing("Oregano", 1, "tbsp", .spices), Ing("Olive oil", 2, "tbsp", .spices, staple: true)]),

        Spec(name: "Mushroom Risotto", summary: "Creamy parmesan risotto with earthy mushrooms.",
             servings: 4, prep: 10, cook: 35, effort: .involved, tags: ["Vegetarian", "Italian", "Comfort"],
             steps: ["Sauté mushrooms; set aside.", "Toast rice with onion.", "Add wine, then warm broth a ladle at a time.",
                     "Stir 20 minutes until creamy.", "Fold in mushrooms, butter and parmesan."],
             ings: [Ing("Arborio rice", 1.5, "cups", .pantry), Ing("Cremini mushrooms", 12, "oz", .produce),
                    Ing("Vegetable broth", 5, "cups", .pantry), Ing("White wine", 0.5, "cup", .pantry),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Parmesan", 0.75, "cup", .dairyEggs),
                    Ing("Butter", 2, "tbsp", .dairyEggs, staple: true)]),

        Spec(name: "Shrimp Fried Rice", summary: "Quick wok-style fried rice with shrimp and egg.",
             servings: 4, prep: 15, cook: 12, effort: .medium, tags: ["Seafood", "Asian", "Fast"],
             steps: ["Scramble eggs; set aside.", "Sear shrimp; set aside.",
                     "Fry rice with vegetables and soy.", "Return shrimp and egg; toss with scallions."],
             ings: [Ing("Cooked rice", 4, "cups", .pantry), Ing("Shrimp", 1, "lb", .meatSeafood),
                    Ing("Eggs", 3, "", .dairyEggs), Ing("Frozen peas", 1, "cup", .frozen),
                    Ing("Carrot", 1, "", .produce), Ing("Soy sauce", 3, "tbsp", .pantry, staple: true),
                    Ing("Scallions", 3, "", .produce)]),

        Spec(name: "Caprese Pasta Salad", summary: "Tomato, mozzarella and basil tossed with pasta.",
             servings: 6, prep: 20, cook: 12, effort: .easy, tags: ["Vegetarian", "Salad", "Meal-Prep"],
             steps: ["Cook pasta; cool under water.", "Halve tomatoes and tear mozzarella.",
                     "Toss with oil, vinegar and basil.", "Season and chill."],
             ings: [Ing("Rotini pasta", 1, "lb", .pantry, staple: true), Ing("Cherry tomatoes", 2, "cups", .produce),
                    Ing("Mozzarella balls", 8, "oz", .dairyEggs), Ing("Basil", 1, "cup", .produce),
                    Ing("Balsamic vinegar", 3, "tbsp", .pantry), Ing("Olive oil", 0.25, "cup", .spices, staple: true)]),

        Spec(name: "Beef & Broccoli", summary: "Tender beef and broccoli in a savory glaze.",
             servings: 4, prep: 20, cook: 15, effort: .medium, tags: ["Beef", "Asian", "Fast"],
             steps: ["Slice and marinate beef.", "Sear beef in batches; set aside.",
                     "Stir-fry broccoli, then add sauce.", "Return beef; toss until glossy."],
             ings: [Ing("Flank steak", 1, "lb", .meatSeafood), Ing("Broccoli", 1, "head", .produce),
                    Ing("Soy sauce", 0.25, "cup", .pantry, staple: true), Ing("Brown sugar", 2, "tbsp", .pantry),
                    Ing("Cornstarch", 1, "tbsp", .pantry), Ing("Ginger", 1, "tbsp", .produce),
                    Ing("Garlic", 3, "cloves", .produce, staple: true), Ing("Rice", 2, "cups", .pantry, staple: true)]),

        Spec(name: "Baked Ziti", summary: "Cheesy baked pasta with marinara and ricotta.",
             servings: 6, prep: 20, cook: 35, effort: .medium, tags: ["Vegetarian", "Italian", "Comfort"],
             steps: ["Cook ziti just under done.", "Mix with marinara and ricotta.",
                     "Layer in a dish with mozzarella.", "Bake 30 minutes until bubbly."],
             ings: [Ing("Ziti", 1, "lb", .pantry, staple: true), Ing("Marinara sauce", 24, "oz", .pantry),
                    Ing("Ricotta", 15, "oz", .dairyEggs), Ing("Mozzarella", 2, "cups", .dairyEggs),
                    Ing("Parmesan", 0.5, "cup", .dairyEggs), Ing("Egg", 1, "", .dairyEggs)]),

        Spec(name: "Lentil Soup", summary: "Cozy, protein-rich lentil and vegetable soup.",
             servings: 6, prep: 15, cook: 35, effort: .easy, tags: ["Vegetarian", "Soup", "Meal-Prep"],
             steps: ["Sauté onion, carrot and celery.", "Add lentils, tomatoes and broth.",
                     "Simmer 30 minutes.", "Finish with spinach and lemon."],
             ings: [Ing("Brown lentils", 1.5, "cups", .pantry), Ing("Carrot", 2, "", .produce),
                    Ing("Celery", 2, "stalks", .produce), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Diced tomatoes", 14, "oz", .pantry), Ing("Vegetable broth", 6, "cups", .pantry),
                    Ing("Spinach", 2, "cups", .produce), Ing("Lemon", 1, "", .produce)]),

        Spec(name: "Pesto Gnocchi", summary: "Pillowy gnocchi tossed with bright basil pesto.",
             servings: 4, prep: 5, cook: 10, effort: .easy, tags: ["Vegetarian", "Italian", "Fast"],
             steps: ["Boil gnocchi until they float.", "Reserve some pasta water.",
                     "Toss with pesto and a splash of water.", "Top with parmesan and pine nuts."],
             ings: [Ing("Potato gnocchi", 1, "lb", .pantry), Ing("Basil pesto", 0.5, "cup", .pantry),
                    Ing("Cherry tomatoes", 1, "cup", .produce), Ing("Parmesan", 0.25, "cup", .dairyEggs),
                    Ing("Pine nuts", 2, "tbsp", .pantry)]),

        Spec(name: "Honey Garlic Pork Chops", summary: "Seared chops glazed in honey and garlic.",
             servings: 4, prep: 10, cook: 15, effort: .easy, tags: ["Pork", "Fast", "Gluten-Free"],
             steps: ["Season chops and sear both sides.", "Add garlic, honey and vinegar.",
                     "Simmer glaze until thick.", "Spoon over chops to finish."],
             ings: [Ing("Pork chops", 4, "", .meatSeafood), Ing("Honey", 0.25, "cup", .pantry),
                    Ing("Garlic", 4, "cloves", .produce, staple: true), Ing("Apple cider vinegar", 2, "tbsp", .pantry),
                    Ing("Butter", 1, "tbsp", .dairyEggs, staple: true), Ing("Salt", 0.5, "tsp", .spices, staple: true)]),

        Spec(name: "Falafel Bowls", summary: "Crispy falafel over greens with tahini drizzle.",
             servings: 4, prep: 20, cook: 15, effort: .medium, tags: ["Vegetarian", "Mediterranean", "Lunch"],
             steps: ["Blend chickpeas with herbs and spices.", "Form patties and pan-fry until golden.",
                     "Build bowls with greens, cucumber and tomato.", "Drizzle with tahini sauce."],
             ings: [Ing("Chickpeas", 2, "cans", .pantry), Ing("Parsley", 1, "cup", .produce),
                    Ing("Cumin", 1, "tsp", .spices), Ing("Tahini", 0.25, "cup", .pantry),
                    Ing("Cucumber", 1, "", .produce), Ing("Cherry tomatoes", 1, "cup", .produce),
                    Ing("Mixed greens", 4, "cups", .produce)]),

        Spec(name: "Egg Fried Noodles", summary: "Saucy noodles with egg and crisp vegetables.",
             servings: 3, prep: 10, cook: 12, effort: .easy, tags: ["Vegetarian", "Asian", "Fast"],
             steps: ["Cook noodles; drain.", "Scramble eggs in a hot wok.",
                     "Add vegetables and noodles.", "Toss with sauce and scallions."],
             ings: [Ing("Egg noodles", 10, "oz", .pantry), Ing("Eggs", 2, "", .dairyEggs),
                    Ing("Cabbage", 2, "cups", .produce), Ing("Carrot", 1, "", .produce),
                    Ing("Soy sauce", 2, "tbsp", .pantry, staple: true), Ing("Sesame oil", 1, "tbsp", .spices),
                    Ing("Scallions", 2, "", .produce)]),

        Spec(name: "Stuffed Bell Peppers", summary: "Peppers filled with rice, beef and tomato.",
             servings: 4, prep: 20, cook: 40, effort: .medium, tags: ["Beef", "Comfort", "Gluten-Free"],
             steps: ["Cook rice; brown beef with onion.", "Mix beef, rice and tomato.",
                     "Stuff halved peppers.", "Bake 35 minutes; top with cheese."],
             ings: [Ing("Bell peppers", 4, "", .produce), Ing("Ground beef", 1, "lb", .meatSeafood),
                    Ing("Cooked rice", 1.5, "cups", .pantry), Ing("Tomato sauce", 1, "cup", .pantry),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Cheddar", 1, "cup", .dairyEggs)]),

        Spec(name: "Coconut Chickpea Curry", summary: "Creamy, comforting chickpea and spinach curry.",
             servings: 4, prep: 10, cook: 25, effort: .easy, tags: ["Vegetarian", "Indian", "Comfort"],
             steps: ["Sauté onion, garlic and ginger.", "Add spices and tomato paste.",
                     "Stir in chickpeas and coconut milk.", "Simmer, then wilt spinach."],
             ings: [Ing("Chickpeas", 2, "cans", .pantry), Ing("Coconut milk", 1, "can", .pantry),
                    Ing("Spinach", 3, "cups", .produce), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Garlic", 3, "cloves", .produce, staple: true), Ing("Ginger", 1, "tbsp", .produce),
                    Ing("Curry powder", 1, "tbsp", .spices), Ing("Tomato paste", 2, "tbsp", .pantry)]),

        Spec(name: "BBQ Chicken Quesadillas", summary: "Smoky BBQ chicken and melty cheese in a crisp tortilla.",
             servings: 4, prep: 15, cook: 12, effort: .easy, tags: ["Chicken", "Mexican", "Fast"],
             steps: ["Toss shredded chicken with BBQ sauce.", "Fill tortillas with chicken and cheese.",
                     "Griddle until golden both sides.", "Slice and serve with extra sauce."],
             ings: [Ing("Cooked chicken", 2, "cups", .meatSeafood), Ing("BBQ sauce", 0.5, "cup", .pantry),
                    Ing("Flour tortillas", 4, "", .bakery), Ing("Cheddar", 2, "cups", .dairyEggs),
                    Ing("Red onion", 0.5, "", .produce)]),

        Spec(name: "Minestrone", summary: "Garden vegetable soup with beans and pasta.",
             servings: 6, prep: 20, cook: 30, effort: .medium, tags: ["Vegetarian", "Soup", "Italian"],
             steps: ["Sauté the soffritto.", "Add tomatoes, broth and beans.",
                     "Simmer 20 minutes.", "Add pasta; cook until tender."],
             ings: [Ing("Cannellini beans", 1, "can", .pantry), Ing("Diced tomatoes", 14, "oz", .pantry),
                    Ing("Carrot", 2, "", .produce), Ing("Celery", 2, "stalks", .produce),
                    Ing("Zucchini", 1, "", .produce), Ing("Vegetable broth", 6, "cups", .pantry),
                    Ing("Small pasta", 1, "cup", .pantry, staple: true), Ing("Onion", 1, "", .produce, staple: true)]),

        Spec(name: "Teriyaki Salmon Bowls", summary: "Glazed salmon over rice with quick cucumber.",
             servings: 2, prep: 10, cook: 15, effort: .easy, tags: ["Fish", "Asian", "Fast"],
             steps: ["Simmer teriyaki until syrupy.", "Roast or pan-sear salmon.",
                     "Glaze salmon with sauce.", "Serve over rice with cucumber."],
             ings: [Ing("Salmon fillets", 2, "", .meatSeafood), Ing("Teriyaki sauce", 0.33, "cup", .pantry),
                    Ing("Rice", 1, "cup", .pantry, staple: true), Ing("Cucumber", 1, "", .produce),
                    Ing("Sesame seeds", 1, "tbsp", .spices), Ing("Scallions", 2, "", .produce)]),

        Spec(name: "Veggie Breakfast Hash", summary: "Crispy potatoes, peppers and eggs in one skillet.",
             servings: 4, prep: 15, cook: 25, effort: .easy, tags: ["Vegetarian", "Breakfast", "One-Pan"],
             steps: ["Crisp diced potatoes in oil.", "Add peppers and onion.",
                     "Make wells and crack in eggs.", "Cover until eggs set."],
             ings: [Ing("Potatoes", 1.5, "lb", .produce), Ing("Bell pepper", 1, "", .produce),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Eggs", 4, "", .dairyEggs),
                    Ing("Paprika", 1, "tsp", .spices), Ing("Olive oil", 2, "tbsp", .spices, staple: true)]),

        Spec(name: "Chicken Noodle Soup", summary: "Classic comforting chicken and noodle soup.",
             servings: 6, prep: 15, cook: 30, effort: .easy, tags: ["Chicken", "Soup", "Comfort"],
             steps: ["Sauté carrot, celery and onion.", "Add broth and chicken; simmer.",
                     "Shred chicken and return.", "Add noodles; cook until tender."],
             ings: [Ing("Chicken breast", 1, "lb", .meatSeafood), Ing("Egg noodles", 8, "oz", .pantry),
                    Ing("Carrot", 3, "", .produce), Ing("Celery", 3, "stalks", .produce),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Chicken broth", 8, "cups", .pantry),
                    Ing("Parsley", 2, "tbsp", .produce)]),

        Spec(name: "Eggplant Parmesan", summary: "Breaded eggplant baked with marinara and cheese.",
             servings: 4, prep: 25, cook: 35, effort: .involved, tags: ["Vegetarian", "Italian", "Comfort"],
             steps: ["Bread eggplant slices.", "Bake until crisp.",
                     "Layer with marinara and cheese.", "Bake until bubbly and golden."],
             ings: [Ing("Eggplant", 2, "", .produce), Ing("Breadcrumbs", 1.5, "cups", .bakery),
                    Ing("Eggs", 2, "", .dairyEggs), Ing("Marinara sauce", 24, "oz", .pantry),
                    Ing("Mozzarella", 2, "cups", .dairyEggs), Ing("Parmesan", 0.5, "cup", .dairyEggs)]),

        Spec(name: "Steak Fajitas", summary: "Sizzling steak with peppers and onions.",
             servings: 4, prep: 20, cook: 15, effort: .medium, tags: ["Beef", "Mexican", "Fast"],
             steps: ["Season and sear steak; rest and slice.", "Char peppers and onions.",
                     "Warm tortillas.", "Serve with lime and toppings."],
             ings: [Ing("Skirt steak", 1, "lb", .meatSeafood), Ing("Bell peppers", 3, "", .produce),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Flour tortillas", 8, "", .bakery),
                    Ing("Lime", 1, "", .produce), Ing("Cumin", 1, "tsp", .spices), Ing("Chili powder", 1, "tsp", .spices)]),

        Spec(name: "Tomato Basil Soup", summary: "Velvety roasted tomato soup with fresh basil.",
             servings: 4, prep: 10, cook: 30, effort: .easy, tags: ["Vegetarian", "Soup", "Comfort"],
             steps: ["Sauté onion and garlic.", "Add tomatoes and broth; simmer.",
                     "Blend until smooth.", "Stir in cream and basil."],
             ings: [Ing("Crushed tomatoes", 28, "oz", .pantry), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Garlic", 3, "cloves", .produce, staple: true), Ing("Vegetable broth", 3, "cups", .pantry),
                    Ing("Heavy cream", 0.5, "cup", .dairyEggs), Ing("Basil", 0.5, "cup", .produce)]),

        Spec(name: "Sausage & Peppers", summary: "Italian sausage simmered with sweet peppers.",
             servings: 4, prep: 10, cook: 25, effort: .easy, tags: ["Pork", "Italian", "One-Pan"],
             steps: ["Brown sausage; set aside.", "Soften peppers and onion.",
                     "Add tomato and return sausage.", "Simmer 15 minutes; serve on rolls."],
             ings: [Ing("Italian sausage", 1, "lb", .meatSeafood), Ing("Bell peppers", 3, "", .produce),
                    Ing("Onion", 1, "", .produce, staple: true), Ing("Crushed tomatoes", 14, "oz", .pantry),
                    Ing("Sub rolls", 4, "", .bakery), Ing("Olive oil", 1, "tbsp", .spices, staple: true)]),

        Spec(name: "Cauliflower Tikka", summary: "Roasted cauliflower in a spiced tomato-cream sauce.",
             servings: 4, prep: 15, cook: 30, effort: .medium, tags: ["Vegetarian", "Indian", "Comfort"],
             steps: ["Roast cauliflower until charred.", "Simmer onion, garlic and spices in tomato.",
                     "Add cream to make the sauce.", "Fold in cauliflower; serve with rice."],
             ings: [Ing("Cauliflower", 1, "head", .produce), Ing("Crushed tomatoes", 14, "oz", .pantry),
                    Ing("Heavy cream", 0.5, "cup", .dairyEggs), Ing("Onion", 1, "", .produce, staple: true),
                    Ing("Garam masala", 1, "tbsp", .spices), Ing("Garlic", 3, "cloves", .produce, staple: true),
                    Ing("Rice", 2, "cups", .pantry, staple: true)]),

        Spec(name: "Tuna Melt Sandwiches", summary: "Toasty tuna melts with sharp cheddar.",
             servings: 2, prep: 10, cook: 8, effort: .easy, tags: ["Fish", "Lunch", "Fast"],
             steps: ["Mix tuna with mayo and celery.", "Pile onto bread with cheese.",
                     "Griddle until golden and melty.", "Slice and serve warm."],
             ings: [Ing("Canned tuna", 2, "cans", .pantry), Ing("Mayonnaise", 3, "tbsp", .pantry),
                    Ing("Celery", 1, "stalk", .produce), Ing("Sourdough bread", 4, "slices", .bakery),
                    Ing("Cheddar", 4, "slices", .dairyEggs)])
    ]
}
