package com.orbioom.forage.data

import com.orbioom.forage.domain.Ingredient
import com.orbioom.forage.domain.Recipe
import com.orbioom.forage.domain.RecipeCategory

/** Real, on-brand starter recipes so a first launch is a populated box, not a void. */
object SampleRecipes {

    fun starter(): List<Recipe> {
        // Stable, increasing timestamps so "recently added" sort is deterministic.
        var t = 1_717_000_000_000L
        fun next(): Long { t += 86_400_000L; return t }

        return listOf(
            Recipe(
                id = "seed-shakshuka",
                title = "Weeknight Shakshuka",
                description = "Eggs poached in a smoky tomato and pepper sauce. One pan, fifteen minutes of real work.",
                category = RecipeCategory.BREAKFAST,
                servings = 2,
                prepMinutes = 10,
                cookMinutes = 20,
                ingredients = listOf(
                    Ingredient("olive oil", 2.0, "tbsp"),
                    Ingredient("onion, sliced", 1.0, ""),
                    Ingredient("red pepper, sliced", 1.0, ""),
                    Ingredient("garlic cloves, sliced", 3.0, ""),
                    Ingredient("smoked paprika", 1.0, "tsp"),
                    Ingredient("ground cumin", 1.0, "tsp"),
                    Ingredient("chopped tomatoes", 400.0, "g"),
                    Ingredient("eggs", 4.0, ""),
                    Ingredient("feta, crumbled", 60.0, "g")
                ),
                steps = listOf(
                    "Warm the oil in a wide pan and soften the onion and pepper for 8 minutes.",
                    "Add the garlic and spices; cook for a minute until fragrant.",
                    "Pour in the tomatoes, season, and simmer until thick, about 8 minutes.",
                    "Make four wells and crack in the eggs. Cover and cook to your liking.",
                    "Scatter over the feta and serve from the pan with bread."
                ),
                tags = listOf("vegetarian", "one-pan", "brunch"),
                favorite = true,
                createdAt = next()
            ),
            Recipe(
                id = "seed-dal",
                title = "Red Lentil Tarka Dal",
                description = "A comforting, forgiving dal finished with a sizzling spiced oil.",
                category = RecipeCategory.MAIN,
                servings = 4,
                prepMinutes = 10,
                cookMinutes = 30,
                ingredients = listOf(
                    Ingredient("red lentils, rinsed", 300.0, "g"),
                    Ingredient("turmeric", 1.0, "tsp"),
                    Ingredient("water", 1.0, "litre"),
                    Ingredient("ghee or oil", 3.0, "tbsp"),
                    Ingredient("cumin seeds", 1.0, "tsp"),
                    Ingredient("garlic cloves, sliced", 4.0, ""),
                    Ingredient("dried chillies", 2.0, ""),
                    Ingredient("salt", 1.0, "tsp")
                ),
                steps = listOf(
                    "Simmer the lentils with turmeric and water until collapsed and soft, 25–30 minutes.",
                    "Whisk to a loose porridge; season with salt.",
                    "In a small pan heat the ghee, then add cumin, garlic and chillies until golden.",
                    "Pour the sizzling tarka over the dal and stir through. Serve with rice."
                ),
                tags = listOf("vegan", "budget", "batch"),
                favorite = false,
                createdAt = next()
            ),
            Recipe(
                id = "seed-roastchicken",
                title = "Lemon & Thyme Roast Chicken",
                description = "The Sunday anchor. Crisp skin, bright juices, easy gravy.",
                category = RecipeCategory.MAIN,
                servings = 4,
                prepMinutes = 15,
                cookMinutes = 80,
                ingredients = listOf(
                    Ingredient("whole chicken", 1.5, "kg"),
                    Ingredient("lemon, halved", 1.0, ""),
                    Ingredient("thyme sprigs", 6.0, ""),
                    Ingredient("butter, softened", 40.0, "g"),
                    Ingredient("flour", 1.0, "tbsp"),
                    Ingredient("chicken stock", 300.0, "ml")
                ),
                steps = listOf(
                    "Heat the oven to 200°C. Pat the chicken dry and rub all over with butter and salt.",
                    "Put the lemon and thyme in the cavity. Roast 75–80 minutes until the juices run clear.",
                    "Rest the bird 15 minutes on a board.",
                    "Spoon off excess fat, stir flour into the tray, then whisk in stock for gravy."
                ),
                tags = listOf("sunday", "classic"),
                favorite = true,
                createdAt = next()
            ),
            Recipe(
                id = "seed-brownies",
                title = "Fudge Brownies",
                description = "Dense, glossy-topped, properly fudgy. The only batch you'll need.",
                category = RecipeCategory.DESSERT,
                servings = 12,
                prepMinutes = 15,
                cookMinutes = 25,
                ingredients = listOf(
                    Ingredient("dark chocolate", 200.0, "g"),
                    Ingredient("butter", 175.0, "g"),
                    Ingredient("caster sugar", 300.0, "g"),
                    Ingredient("eggs", 3.0, ""),
                    Ingredient("plain flour", 100.0, "g"),
                    Ingredient("cocoa powder", 40.0, "g")
                ),
                steps = listOf(
                    "Heat the oven to 180°C and line a 20cm tin.",
                    "Melt the chocolate and butter together, then cool slightly.",
                    "Whisk in the sugar and eggs until glossy.",
                    "Fold in the flour and cocoa. Bake 22–25 minutes until just set.",
                    "Cool fully before cutting into squares."
                ),
                tags = listOf("baking", "crowd-pleaser"),
                favorite = false,
                createdAt = next()
            ),
            Recipe(
                id = "seed-greenslaw",
                title = "Crunchy Green Slaw",
                description = "A sharp, herby side that wakes up anything off the grill.",
                category = RecipeCategory.SIDE,
                servings = 6,
                prepMinutes = 15,
                cookMinutes = 0,
                ingredients = listOf(
                    Ingredient("white cabbage, shredded", 0.5, ""),
                    Ingredient("apple, julienned", 1.0, ""),
                    Ingredient("spring onions, sliced", 4.0, ""),
                    Ingredient("greek yoghurt", 4.0, "tbsp"),
                    Ingredient("dijon mustard", 1.0, "tsp"),
                    Ingredient("cider vinegar", 1.0, "tbsp"),
                    Ingredient("dill, chopped", 1.0, "handful")
                ),
                steps = listOf(
                    "Whisk the yoghurt, mustard and vinegar with salt and pepper.",
                    "Toss through the cabbage, apple and spring onions.",
                    "Fold in the dill and let it sit 10 minutes before serving."
                ),
                tags = listOf("vegetarian", "no-cook", "bbq"),
                favorite = false,
                createdAt = next()
            ),
            Recipe(
                id = "seed-negroni",
                title = "House Negroni",
                description = "Equal parts, stirred, one big cube. Bitter, balanced, done.",
                category = RecipeCategory.DRINK,
                servings = 1,
                prepMinutes = 3,
                cookMinutes = 0,
                ingredients = listOf(
                    Ingredient("gin", 30.0, "ml"),
                    Ingredient("campari", 30.0, "ml"),
                    Ingredient("sweet vermouth", 30.0, "ml"),
                    Ingredient("orange peel", 1.0, "")
                ),
                steps = listOf(
                    "Stir the gin, Campari and vermouth over ice until well chilled.",
                    "Strain over a large cube in a rocks glass.",
                    "Express the orange peel over the top and drop it in."
                ),
                tags = listOf("cocktail", "aperitivo"),
                favorite = false,
                createdAt = next()
            )
        )
    }
}
