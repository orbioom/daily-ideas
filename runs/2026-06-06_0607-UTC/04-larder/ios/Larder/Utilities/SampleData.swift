import Foundation
import SwiftData

/// Seeds a realistic, lived-in larder on first launch: four locations, eight
/// categories, and 20+ items with dates spread so some are expired, some expiring
/// soon, and some fresh — and a few sitting at/below their low-stock threshold — so
/// the dashboard and shopping list are alive immediately.
enum SampleData {

    /// Builds the default locations (also used by the editor when none exist yet).
    static func defaultLocations() -> [Location] {
        [
            Location(name: "Pantry", symbol: "cabinet", sortIndex: 0),
            Location(name: "Fridge", symbol: "refrigerator", sortIndex: 1),
            Location(name: "Freezer", symbol: "snowflake", sortIndex: 2),
            Location(name: "Spice Rack", symbol: "leaf", sortIndex: 3)
        ]
    }

    /// Builds the default categories.
    static func defaultCategories() -> [Category] {
        [
            Category(name: "Grains", symbol: "circle.grid.2x2", colorHue: 0),
            Category(name: "Dairy", symbol: "drop.fill", colorHue: 1),
            Category(name: "Produce", symbol: "carrot.fill", colorHue: 5),
            Category(name: "Meat", symbol: "fork.knife", colorHue: 6),
            Category(name: "Canned", symbol: "cylinder.fill", colorHue: 8),
            Category(name: "Baking", symbol: "birthday.cake.fill", colorHue: 2),
            Category(name: "Condiments", symbol: "takeoutbag.and.cup.and.straw.fill", colorHue: 3),
            Category(name: "Spices", symbol: "leaf.fill", colorHue: 4)
        ]
    }

    /// Inserts the full sample set. Idempotent guard lives in the caller (RootView).
    static func insert(into context: ModelContext) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        func day(_ offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: today) ?? today
        }

        let locations = defaultLocations()
        let categories = defaultCategories()
        locations.forEach { context.insert($0) }
        categories.forEach { context.insert($0) }

        func loc(_ name: String) -> Location? { locations.first { $0.name == name } }
        func cat(_ name: String) -> Category? { categories.first { $0.name == name } }

        // (name, qty, unit, locationName, categoryName, purchaseOffset, expiryOffset, threshold, notes)
        let rows: [(String, Double, Unit, String, String, Int, Int?, Double, String)] = [
            ("Whole Milk", 1, .liter, "Fridge", "Dairy", -3, 2, 1, "Semi-skimmed alternative in door"),
            ("Greek Yoghurt", 2, .pack, "Fridge", "Dairy", -5, -1, 1, ""),
            ("Cheddar Block", 1, .piece, "Fridge", "Dairy", -10, 9, 1, "Mature"),
            ("Eggs", 4, .piece, "Fridge", "Dairy", -6, 4, 6, "Free range half-dozen"),
            ("Spinach", 1, .bag, "Fridge", "Produce", -2, 1, 1, "Pre-washed"),
            ("Carrots", 6, .piece, "Fridge", "Produce", -4, 8, 3, ""),
            ("Chicken Breast", 2, .pack, "Freezer", "Meat", -14, 60, 1, "Portioned"),
            ("Minced Beef", 1, .pack, "Freezer", "Meat", -20, 45, 1, ""),
            ("Frozen Peas", 1, .bag, "Freezer", "Produce", -30, 120, 1, ""),
            ("Sourdough Loaf", 1, .piece, "Pantry", "Grains", -2, 1, 1, "Half left"),
            ("Basmati Rice", 1, .kilogram, "Pantry", "Grains", -40, 300, 1, ""),
            ("Spaghetti", 3, .pack, "Pantry", "Grains", -25, 250, 2, ""),
            ("Rolled Oats", 1, .box, "Pantry", "Grains", -18, 120, 1, "Breakfast"),
            ("Plain Flour", 1, .kilogram, "Pantry", "Baking", -50, 200, 1, ""),
            ("Caster Sugar", 1, .kilogram, "Pantry", "Baking", -60, 365, 1, ""),
            ("Baking Powder", 1, .jar, "Pantry", "Baking", -90, 30, 1, "Check the date"),
            ("Chopped Tomatoes", 4, .can, "Pantry", "Canned", -45, 400, 2, ""),
            ("Chickpeas", 2, .can, "Pantry", "Canned", -45, 380, 2, ""),
            ("Tuna", 1, .can, "Pantry", "Canned", -30, 420, 3, "Running low"),
            ("Olive Oil", 1, .bottle, "Pantry", "Condiments", -35, 200, 1, "Extra virgin"),
            ("Soy Sauce", 1, .bottle, "Fridge", "Condiments", -120, 90, 1, ""),
            ("Ketchup", 1, .bottle, "Fridge", "Condiments", -20, 70, 1, ""),
            ("Ground Cumin", 1, .jar, "Spice Rack", "Spices", -200, 5, 1, "Nearly out of date"),
            ("Smoked Paprika", 1, .jar, "Spice Rack", "Spices", -150, 80, 1, ""),
            ("Black Peppercorns", 1, .jar, "Spice Rack", "Spices", -180, 400, 1, ""),
            ("Butter", 1, .pack, "Fridge", "Dairy", -7, 0, 1, "Use today")
        ]

        for row in rows {
            let item = Item(
                name: row.0,
                quantity: row.1,
                unit: row.2,
                purchaseDate: day(row.5),
                expiryDate: row.6.map { day($0) },
                lowStockThreshold: row.7,
                notes: row.8,
                location: loc(row.3),
                category: cat(row.4))
            context.insert(item)
        }

        // A manual shopping-list entry so the list has both kinds out of the gate.
        context.insert(ShoppingListEntry(name: "Kitchen Roll", desiredText: "2", isManual: true))

        try? context.save()
    }
}
