import Foundation
import SwiftData

/// Seeds realistic sample content on first launch, guarded so it runs exactly once.
enum SeedData {
    private static let seededKey = "didSeedSampleData_v1"

    @MainActor
    static func seedIfNeeded(_ context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: seededKey) else { return }

        seedWallpapers(context)
        seedPalettes(context)

        do {
            try context.save()
            defaults.set(true, forKey: seededKey)
        } catch {
            // If saving fails we leave the flag unset so seeding can be retried next launch.
            defaults.set(false, forKey: seededKey)
        }
    }

    @MainActor
    private static func seedWallpapers(_ context: ModelContext) {
        let recipes: [(String, WallpaperStyle, String, UInt64, Double, Double, Bool)] = [
            ("Ember Sweep", .linearGradient, "sun-ember", 11, 110, 0.12, true),
            ("Cotton Bloom", .meshGradient, "pas-cotton", 22, 0, 0.10, false),
            ("Forest Facets", .lowPoly, "earth-forest", 33, 0, 0.14, true),
            ("Slate Bands", .stripes, "mono-slate", 44, 30, 0.08, false),
            ("Neon Field", .dotField, "neon-vapor", 55, 0, 0.10, true),
            ("Deep Aurora", .aurora, "ocean-deep", 66, 12, 0.20, false),
            ("Create Boldly", .quote, "mono-violet", 77, 60, 0.10, false),
            ("Coral Mist", .meshGradient, "sun-coral", 88, 0, 0.16, false),
            ("Tide Lines", .stripes, "ocean-tide", 99, 90, 0.06, true),
            ("Cyber Poly", .lowPoly, "neon-cyber", 110, 0, 0.12, false)
        ]

        for (index, recipe) in recipes.enumerated() {
            let pal = BuiltInPalettes.palette(withID: recipe.2) ?? BuiltInPalettes.defaultPalette
            let spec = WallpaperSpec(
                style: recipe.1,
                paletteHexes: pal.hexes,
                paletteName: pal.name,
                seed: recipe.3,
                angle: recipe.4,
                grain: recipe.5,
                vignette: 0.18,
                blur: recipe.1 == .meshGradient ? 0.4 : 0,
                complexity: 6 + (index % 6),
                quoteText: recipe.1 == .quote ? "Create boldly." : nil,
                quoteWeightRaw: 3
            )
            let model = SavedWallpaper(
                name: recipe.0,
                specData: SavedWallpaper.encode(spec),
                createdAt: Date().addingTimeInterval(-Double(index) * 3600),
                isFavorite: recipe.6
            )
            context.insert(model)
        }
    }

    @MainActor
    private static func seedPalettes(_ context: ModelContext) {
        let samples: [(String, [String])] = [
            ("My Sunrise", ["FFB75E", "ED8F03", "C2334D"]),
            ("Studio Violet", ["2B1055", "7C5CFF", "C2E9FB"])
        ]
        for (name, hexes) in samples {
            context.insert(CustomPalette(name: name, hexes: hexes))
        }
    }
}
