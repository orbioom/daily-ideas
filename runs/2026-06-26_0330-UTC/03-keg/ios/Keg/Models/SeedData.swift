import Foundation
import SwiftData

enum SeedData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let cal = Calendar.current
        let now = Date()

        // Recipe 1: American IPA
        let ipa = Recipe(
            name: "Cascade IPA",
            beerStyle: BeerStyle.ipa.rawValue,
            batchSizeLiters: 19,
            originalGravity: 1.065,
            finalGravity: 1.013,
            ibu: 65,
            srm: 7,
            efficiency: 0.75,
            notes: "Classic American IPA with citrus and floral notes from Cascade hops.",
            tags: "citrus,hoppy,classic"
        )
        context.insert(ipa)
        ipa.isFavorite = true

        addGrain(context: context, recipe: ipa, name: "American 2-Row Pale Malt", amount: 4500, order: 0)
        addGrain(context: context, recipe: ipa, name: "Crystal 60L", amount: 450, order: 1)
        addGrain(context: context, recipe: ipa, name: "Munich Malt", amount: 225, order: 2)
        addHop(context: context, recipe: ipa, name: "Cascade", amount: 28, alpha: 7.0, mins: 60, order: 3)
        addHop(context: context, recipe: ipa, name: "Cascade", amount: 14, alpha: 7.0, mins: 15, order: 4)
        addHop(context: context, recipe: ipa, name: "Cascade", amount: 28, alpha: 7.0, mins: 0, order: 5)
        addYeast(context: context, recipe: ipa, name: "US-05 American Ale", order: 6)

        // Recipe 2: Oatmeal Stout
        let stout = Recipe(
            name: "Winter Oatmeal Stout",
            beerStyle: BeerStyle.stout.rawValue,
            batchSizeLiters: 19,
            originalGravity: 1.058,
            finalGravity: 1.014,
            ibu: 30,
            srm: 35,
            efficiency: 0.72,
            notes: "Rich and creamy with chocolate and coffee notes. Perfect for cold evenings.",
            tags: "dark,chocolate,coffee,winter"
        )
        context.insert(stout)

        addGrain(context: context, recipe: stout, name: "Maris Otter Pale Malt", amount: 3600, order: 0)
        addGrain(context: context, recipe: stout, name: "Oats (Flaked)", amount: 600, order: 1)
        addGrain(context: context, recipe: stout, name: "Chocolate Malt", amount: 350, order: 2)
        addGrain(context: context, recipe: stout, name: "Roasted Barley", amount: 250, order: 3)
        addGrain(context: context, recipe: stout, name: "Crystal 80L", amount: 200, order: 4)
        addHop(context: context, recipe: stout, name: "East Kent Goldings", amount: 42, alpha: 5.0, mins: 60, order: 5)
        addYeast(context: context, recipe: stout, name: "Wyeast 1084 Irish Ale", order: 6)

        // Recipe 3: German Hefeweizen
        let wheat = Recipe(
            name: "Bavarian Hefeweizen",
            beerStyle: BeerStyle.wheat.rawValue,
            batchSizeLiters: 23,
            originalGravity: 1.050,
            finalGravity: 1.012,
            ibu: 14,
            srm: 4,
            efficiency: 0.74,
            notes: "Classic Bavarian hefeweizen with banana and clove yeast character.",
            tags: "wheat,banana,clove,german,summer"
        )
        context.insert(wheat)

        addGrain(context: context, recipe: wheat, name: "White Wheat Malt", amount: 2800, order: 0)
        addGrain(context: context, recipe: wheat, name: "Pilsner Malt", amount: 2000, order: 1)
        addHop(context: context, recipe: wheat, name: "Hallertau Tradition", amount: 28, alpha: 4.5, mins: 60, order: 2)
        addYeast(context: context, recipe: wheat, name: "WY3068 Weihenstephan Weizen", order: 3)

        // Recipe 4: Amber Ale
        let amber = Recipe(
            name: "Autumn Amber Ale",
            beerStyle: BeerStyle.ale.rawValue,
            batchSizeLiters: 19,
            originalGravity: 1.054,
            finalGravity: 1.013,
            ibu: 28,
            srm: 12,
            efficiency: 0.75,
            notes: "Balanced amber ale with caramel malt sweetness and mild hop bitterness.",
            tags: "caramel,amber,balanced"
        )
        context.insert(amber)

        addGrain(context: context, recipe: amber, name: "American 2-Row Pale Malt", amount: 3800, order: 0)
        addGrain(context: context, recipe: amber, name: "Crystal 40L", amount: 500, order: 1)
        addGrain(context: context, recipe: amber, name: "Crystal 80L", amount: 200, order: 2)
        addGrain(context: context, recipe: amber, name: "Carapils", amount: 100, order: 3)
        addHop(context: context, recipe: amber, name: "Columbus", amount: 14, alpha: 14.0, mins: 60, order: 4)
        addHop(context: context, recipe: amber, name: "Centennial", amount: 14, alpha: 10.0, mins: 10, order: 5)
        addYeast(context: context, recipe: amber, name: "US-05 American Ale", order: 6)

        // Recipe 5: Kölsch
        let kolsch = Recipe(
            name: "Summer Kölsch",
            beerStyle: BeerStyle.ale.rawValue,
            batchSizeLiters: 19,
            originalGravity: 1.047,
            finalGravity: 1.010,
            ibu: 20,
            srm: 3,
            efficiency: 0.78,
            notes: "Light, crisp Kölsch-style ale. Ferment cold for clean lager-like character.",
            tags: "light,crisp,summer,clean"
        )
        context.insert(kolsch)

        addGrain(context: context, recipe: kolsch, name: "Pilsner Malt", amount: 3600, order: 0)
        addGrain(context: context, recipe: kolsch, name: "Wheat Malt", amount: 400, order: 1)
        addHop(context: context, recipe: kolsch, name: "Hallertau Mittelfrüh", amount: 28, alpha: 4.0, mins: 60, order: 2)
        addHop(context: context, recipe: kolsch, name: "Spalt Select", amount: 14, alpha: 4.0, mins: 10, order: 3)
        addYeast(context: context, recipe: kolsch, name: "WY2565 Kölsch", order: 4)

        // Now create batches for the IPA and Stout
        let ipaBatch1 = BrewBatch(
            batchNumber: 1,
            brewDate: cal.date(byAdding: .day, value: -60, to: now) ?? now,
            status: "complete",
            actualOG: 1.063,
            actualFG: 1.013,
            actualVolumeLiters: 19,
            fermentationTempC: 19,
            notes: "Great first batch! Slight underattenuation."
        )
        ipaBatch1.recipe = ipa
        context.insert(ipaBatch1)

        let ipaBatch2 = BrewBatch(
            batchNumber: 2,
            brewDate: cal.date(byAdding: .day, value: -20, to: now) ?? now,
            status: "conditioning",
            actualOG: 1.066,
            actualFG: 1.011,
            actualVolumeLiters: 20,
            fermentationTempC: 19,
            notes: "Increased dry hop to 56g total. Much more aroma."
        )
        ipaBatch2.recipe = ipa
        context.insert(ipaBatch2)

        // Fermentation logs for batch 2
        let logs: [(Int, Double, Double)] = [
            (0, 1.066, 19.0),
            (2, 1.038, 20.5),
            (4, 1.020, 21.0),
            (7, 1.013, 20.0),
            (10, 1.012, 19.5),
            (14, 1.011, 19.0),
        ]
        for (daysAgo, grav, temp) in logs {
            let logDate = cal.date(byAdding: .day, value: -(20 - daysAgo), to: now) ?? now
            let log = FermentationLog(date: logDate, gravity: grav, tempC: temp)
            log.batch = ipaBatch2
            context.insert(log)
        }

        let stoutBatch = BrewBatch(
            batchNumber: 1,
            brewDate: cal.date(byAdding: .day, value: -90, to: now) ?? now,
            status: "complete",
            actualOG: 1.056,
            actualFG: 1.016,
            actualVolumeLiters: 18.5,
            fermentationTempC: 18,
            notes: "Very smooth. Will increase oat bill next time."
        )
        stoutBatch.recipe = stout
        context.insert(stoutBatch)

        let amberBatch = BrewBatch(
            batchNumber: 1,
            brewDate: cal.date(byAdding: .day, value: -7, to: now) ?? now,
            status: "fermenting",
            actualOG: 1.055,
            actualFG: 0,
            actualVolumeLiters: 19,
            fermentationTempC: 19,
            notes: "Active fermentation. Smells great."
        )
        amberBatch.recipe = amber
        context.insert(amberBatch)

        try? context.save()
    }

    private static func addGrain(context: ModelContext, recipe: Recipe, name: String, amount: Double, order: Int) {
        let ing = RecipeIngredient(ingredientType: IngredientType.grain.rawValue, name: name, amountGrams: amount, sortOrder: order)
        ing.recipe = recipe
        context.insert(ing)
    }

    private static func addHop(context: ModelContext, recipe: Recipe, name: String, amount: Double, alpha: Double, mins: Int, order: Int) {
        let ing = RecipeIngredient(
            ingredientType: IngredientType.hop.rawValue,
            name: name,
            amountGrams: amount,
            sortOrder: order,
            alphaAcidPercent: alpha,
            additionMinutes: mins
        )
        ing.recipe = recipe
        context.insert(ing)
    }

    private static func addYeast(context: ModelContext, recipe: Recipe, name: String, order: Int) {
        let ing = RecipeIngredient(ingredientType: IngredientType.yeast.rawValue, name: name, amountGrams: 11.5, sortOrder: order)
        ing.recipe = recipe
        context.insert(ing)
    }
}
