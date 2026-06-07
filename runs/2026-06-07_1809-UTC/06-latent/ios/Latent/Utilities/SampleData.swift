import Foundation
import SwiftData

/// Seeds a fresh install with believable content so every screen — recipes, the
/// develop setup, the log, and its insights — looks alive on first run. Only ever
/// inserts when the relevant store is empty; never auto-starts a timer.
enum SampleData {

    /// Insert sample recipes and past sessions if the store is currently empty.
    /// Safe to call repeatedly: it no-ops once data exists.
    @MainActor
    static func seedIfEmpty(_ context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        guard existing.isEmpty else { return }

        let recipes = seedRecipes(context)
        seedSessions(context, recipes: recipes)

        try? context.save()
    }

    // MARK: - Recipes

    /// Turn the first eight catalog entries into saved recipes.
    @MainActor
    private static func seedRecipes(_ context: ModelContext) -> [Recipe] {
        let picks = Array(FilmCatalog.all.prefix(8))
        var made: [Recipe] = []
        for ref in picks {
            let r = Recipe(
                name: ref.suggestedName,
                filmStock: ref.filmStock,
                developer: ref.developer,
                dilution: ref.dilution,
                boxISO: ref.boxISO,
                baseTimeSec: ref.baseTimeSec,
                baseTempC: 20.0,
                agitationNote: ref.agitationNote,
                stopSec: ref.stopSec,
                fixSec: ref.fixSec,
                washSec: ref.washSec,
                notes: ""
            )
            context.insert(r)
            made.append(r)
        }
        return made
    }

    // MARK: - Sessions

    /// Seven past developing runs spread over recent weeks, at varied
    /// temperatures and push/pulls, with ratings and short notes.
    @MainActor
    private static func seedSessions(_ context: ModelContext, recipes: [Recipe]) {
        guard !recipes.isEmpty else { return }

        // (recipeIndex, daysAgo, tempC, push, rolls, rating, ei, notes)
        let plan: [(Int, Int, Double, Int, Int, Int, Int, String)] = [
            (0,  2, 20.0,  0, 2, 5, 400, "Lovely tonality. Standard agitation, no surprises."),
            (1,  5, 22.5,  1, 1, 4, 800, "Pushed to 800 for an overcast street walk. A touch contrasty."),
            (3,  9, 19.0,  0, 1, 5, 100, "Delta 100 fine grain, water bath kept it cool."),
            (0, 13, 24.0,  0, 3, 3, 400, "Tap water ran warm; shorter dev. Slightly thin negs."),
            (5, 18, 20.0,  2, 1, 4, 1600, "Two-stop push for a concert. Grainy but printable."),
            (2, 24, 20.0, -1, 1, 4, 200, "Pulled a stop to tame harsh midday sun. Smooth."),
            (4, 31, 21.0,  0, 2, 5, 125, "FP4+ classic. Best batch this month.")
        ]

        let cal = Calendar.current
        for (ri, days, temp, push, rolls, rating, ei, note) in plan {
            let recipe = recipes[min(ri, recipes.count - 1)]
            let date = cal.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let dev = DevEngine.adjustedDevSec(
                baseTimeSec: recipe.baseTimeSec,
                baseTempC: recipe.baseTempC,
                tempC: temp,
                pushPull: push
            )
            let s = DevSession(
                date: date,
                recipeName: recipe.name,
                filmStock: recipe.filmStock,
                developer: recipe.developer,
                dilution: recipe.dilution,
                ei: ei,
                tempC: temp,
                pushPull: push,
                devSec: dev,
                stopSec: recipe.stopSec,
                fixSec: recipe.fixSec,
                washSec: recipe.washSec,
                rolls: rolls,
                rating: rating,
                notes: note,
                recipe: recipe
            )
            context.insert(s)
        }
    }
}
