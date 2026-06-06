import Foundation
import SwiftData

/// Seeds a realistic home bar and a set of classic cocktails so the match
/// engine has something to chew on immediately.
enum SampleData {
    static func seed(into context: ModelContext) {
        // name: (category, inStock)
        let defs: [(String, IngredientCategory, Bool)] = [
            ("Gin", .spirit, true), ("Vodka", .spirit, true), ("White Rum", .spirit, true),
            ("Bourbon", .spirit, true), ("Tequila Blanco", .spirit, true),
            ("Rye Whiskey", .spirit, false), ("Mezcal", .spirit, false), ("Cognac", .spirit, false),
            ("Cointreau", .liqueur, true), ("Campari", .liqueur, true), ("Coffee Liqueur", .liqueur, true),
            ("Aperol", .liqueur, false), ("Maraschino", .liqueur, false), ("Orange Curaçao", .liqueur, false),
            ("Sweet Vermouth", .wine, true), ("Dry Vermouth", .wine, true), ("Prosecco", .wine, false),
            ("Angostura Bitters", .bitters, true), ("Orange Bitters", .bitters, true),
            ("Lime Juice", .juice, true), ("Lemon Juice", .juice, false),
            ("Cranberry Juice", .juice, false),
            ("Simple Syrup", .syrup, true), ("Grenadine", .syrup, false), ("Orgeat", .syrup, false),
            ("Soda Water", .mixer, true), ("Tonic Water", .mixer, true), ("Grapefruit Soda", .mixer, false),
            ("Espresso", .other, false), ("Mint", .garnish, true), ("Orange Peel", .garnish, true),
            ("Lime Wheel", .garnish, true), ("Lemon Twist", .garnish, true),
            ("Cherry", .garnish, true), ("Olive", .garnish, true),
        ]
        var byName: [String: Ingredient] = [:]
        for d in defs {
            let ing = Ingredient(name: d.0, category: d.1, inStock: d.2)
            context.insert(ing); byName[d.0] = ing
        }

        func recipe(_ name: String, _ method: Method, _ glass: String, _ instr: String,
                    favorite: Bool = false,
                    _ parts: [(String, Double, Measure, Bool)]) {
            let r = Recipe(name: name, method: method, glass: glass, instructions: instr, favorite: favorite)
            context.insert(r)
            for p in parts {
                let c = RecipeComponent(amount: p.1, measure: p.2, optional: p.3, ingredient: byName[p.0])
                c.recipe = r
                context.insert(c)
                r.components.append(c)
            }
        }

        recipe("Margarita", .shaken, "Coupe", "Shake with ice, strain. Salt rim optional.", favorite: true,
               [("Tequila Blanco", 2, .oz, false), ("Cointreau", 1, .oz, false),
                ("Lime Juice", 1, .oz, false), ("Lime Wheel", 1, .piece, true)])
        recipe("Daiquiri", .shaken, "Coupe", "Shake hard with ice, double strain.", favorite: true,
               [("White Rum", 2, .oz, false), ("Lime Juice", 1, .oz, false), ("Simple Syrup", 0.75, .oz, false)])
        recipe("Negroni", .stirred, "Rocks", "Stir with ice, strain over a big cube.",
               [("Gin", 1, .oz, false), ("Campari", 1, .oz, false),
                ("Sweet Vermouth", 1, .oz, false), ("Orange Peel", 1, .piece, true)])
        recipe("Old Fashioned", .stirred, "Rocks", "Stir, strain over ice, express the peel.",
               [("Bourbon", 2, .oz, false), ("Simple Syrup", 0.25, .oz, false),
                ("Angostura Bitters", 2, .dash, false), ("Orange Peel", 1, .piece, true)])
        recipe("Gin & Tonic", .built, "Highball", "Build over ice, top with tonic.",
               [("Gin", 2, .oz, false), ("Tonic Water", 1, .topUp, false), ("Lime Wheel", 1, .piece, true)])
        recipe("Mojito", .built, "Highball", "Muddle mint, build, top with soda.",
               [("White Rum", 2, .oz, false), ("Lime Juice", 1, .oz, false),
                ("Simple Syrup", 0.5, .oz, false), ("Mint", 1, .piece, false), ("Soda Water", 1, .topUp, false)])
        recipe("Manhattan", .stirred, "Coupe", "Stir with ice, strain.",
               [("Rye Whiskey", 2, .oz, false), ("Sweet Vermouth", 1, .oz, false),
                ("Angostura Bitters", 2, .dash, false), ("Cherry", 1, .piece, true)])
        recipe("Cosmopolitan", .shaken, "Coupe", "Shake with ice, double strain.",
               [("Vodka", 1.5, .oz, false), ("Cointreau", 0.5, .oz, false),
                ("Lime Juice", 0.5, .oz, false), ("Cranberry Juice", 0.75, .oz, false)])
        recipe("Espresso Martini", .shaken, "Coupe", "Shake very hard for foam, double strain.",
               [("Vodka", 1.5, .oz, false), ("Coffee Liqueur", 1, .oz, false),
                ("Simple Syrup", 0.25, .oz, false), ("Espresso", 1, .oz, false)])
        recipe("Whiskey Sour", .shaken, "Rocks", "Dry shake, then shake with ice.",
               [("Bourbon", 2, .oz, false), ("Lemon Juice", 0.75, .oz, false), ("Simple Syrup", 0.75, .oz, false)])
        recipe("Tom Collins", .built, "Collins", "Shake first three, top with soda.",
               [("Gin", 2, .oz, false), ("Lemon Juice", 0.75, .oz, false),
                ("Simple Syrup", 0.75, .oz, false), ("Soda Water", 1, .topUp, false)])
        recipe("Paloma", .built, "Highball", "Build over ice, top with grapefruit soda.",
               [("Tequila Blanco", 2, .oz, false), ("Lime Juice", 0.5, .oz, false),
                ("Grapefruit Soda", 1, .topUp, false)])
        recipe("Aperol Spritz", .built, "Wine", "Build over ice: 3-2-1, soda splash.",
               [("Aperol", 3, .oz, false), ("Prosecco", 3, .oz, false), ("Soda Water", 1, .splash, false)])
        recipe("Mai Tai", .shaken, "Rocks", "Shake with crushed ice.",
               [("White Rum", 2, .oz, false), ("Orange Curaçao", 0.5, .oz, false),
                ("Orgeat", 0.5, .oz, false), ("Lime Juice", 1, .oz, false)])

        try? context.save()
    }
}
