import Foundation
import SwiftData

/// Seeds realistic sample data on first launch so Favorites, Custom foods and
/// the Cook Log feel alive immediately. Guarded by an @AppStorage flag → runs once.
enum SeedData {

    private static let seededKey = "didSeedV1"

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: seededKey) { return }
        defaults.set(true, forKey: seededKey)

        seedFavorites(context)
        seedCustomFoods(context)
        seedCookLogs(context)

        try? context.save()
    }

    private static func seedFavorites(_ context: ModelContext) {
        let ids = [
            "chicken-wings", "salmon", "frozen-fries", "broccoli", "chicken-breast",
            "steak", "brussels", "shrimp", "tofu", "nuggets", "bacon", "potatoes-wedges",
        ]
        let now = Date()
        for (i, foodId) in ids.enumerated() where FoodCatalog.byId[foodId] != nil {
            let added = now.addingTimeInterval(TimeInterval(-i * 86_400))
            context.insert(FavoriteFood(foodId: foodId, addedAt: added))
        }
    }

    private static func seedCustomFoods(_ context: ModelContext) {
        let customs: [(String, FoodCategory, Int, Int, String)] = [
            ("Mom's Empanadas", .frozen, 380, 13, "From frozen. Spritz with oil; flip at 6 min."),
            ("Spicy Paneer Tikka", .snacks, 400, 14, "Marinate 30 min. Shake twice for char."),
            ("Garlic Naan Bites", .baked, 350, 6, "Brush with butter the second they come out."),
        ]
        for c in customs {
            context.insert(CustomFood(name: c.0, categoryRaw: c.1.rawValue, tempF: c.2, minutes: c.3, notes: c.4))
        }
    }

    private static func seedCookLogs(_ context: ModelContext) {
        // ~30 entries spread across the past ~6 weeks.
        let samples: [(String, String, Int, Int)] = [
            ("chicken-wings", "Chicken Wings", 380, 24),
            ("salmon", "Salmon Fillet", 390, 9),
            ("frozen-fries", "Fries", 400, 16),
            ("broccoli", "Broccoli", 375, 10),
            ("steak", "Steak", 400, 10),
            ("brussels", "Brussels Sprouts", 375, 14),
            ("shrimp", "Shrimp", 400, 7),
            ("tofu", "Tofu", 390, 15),
            ("nuggets", "Chicken Nuggets", 380, 11),
            ("bacon", "Bacon", 350, 9),
            ("chicken-breast", "Chicken Breast", 375, 18),
            ("potatoes-wedges", "Potato Wedges", 400, 22),
            ("pork-chops", "Pork Chops", 375, 14),
            ("sweet-potato", "Sweet Potato", 380, 18),
            ("chickpeas", "Crispy Chickpeas", 390, 15),
        ]
        let cal = Calendar.current
        let today = Date()

        // Two passes over the sample set gives ~30 entries spread across ~6 weeks.
        var dayOffset = 1
        for _ in 0..<2 {
            for (i, s) in samples.enumerated() {
                // Spread entries roughly every 1–2 days going backwards.
                dayOffset += Int.random(in: 1...2)
                let date = cal.date(byAdding: .day, value: -dayOffset, to: today) ?? today
                let rating = Int.random(in: 3...5)
                let note = (i % 4 == 0) ? "Perfectly crisp." : ""
                context.insert(
                    CookLog(foodId: s.0, name: s.1, date: date, tempF: s.2, minutes: s.3, rating: rating, note: note)
                )
            }
        }
    }
}
