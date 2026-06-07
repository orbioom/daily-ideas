import Foundation

/// A doneness level for a food, with its target bath temperature.
struct DonenessLevel: Identifiable {
    let id = UUID()
    let name: String
    let celsius: Double
    let detail: String
}

/// A food preset with shape, default thickness, and doneness options.
struct FoodPreset: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let shape: FoodShape
    let defaultThicknessMM: Double
    let levels: [DonenessLevel]
    let note: String

    var symbol: String {
        switch category {
        case "Beef": return "flame"
        case "Poultry": return "bird"
        case "Pork": return "fork.knife"
        case "Seafood": return "fish"
        case "Egg": return "oval.portrait"
        case "Vegetable": return "carrot"
        default: return "circle"
        }
    }
}

/// Static reference of common sous-vide foods and their temperatures.
enum DonenessGuide {
    static let presets: [FoodPreset] = [
        FoodPreset(name: "Beef steak", category: "Beef", shape: .slab, defaultThicknessMM: 25, levels: [
            DonenessLevel(name: "Rare", celsius: 50, detail: "Soft, very red"),
            DonenessLevel(name: "Medium-rare", celsius: 54.5, detail: "The classic"),
            DonenessLevel(name: "Medium", celsius: 57, detail: "Pink, firmer"),
            DonenessLevel(name: "Medium-well", celsius: 63, detail: "Barely pink")
        ], note: "Sear hard after the bath. 1 in / 25 mm is typical."),
        FoodPreset(name: "Beef roast", category: "Beef", shape: .cylinder, defaultThicknessMM: 70, levels: [
            DonenessLevel(name: "Medium-rare", celsius: 56, detail: "Tender, juicy"),
            DonenessLevel(name: "Medium", celsius: 60, detail: "Firmer")
        ], note: "Thick roasts need long holds — these are great overnight."),
        FoodPreset(name: "Chicken breast", category: "Poultry", shape: .slab, defaultThicknessMM: 35, levels: [
            DonenessLevel(name: "Silky", celsius: 60, detail: "Very tender, just set"),
            DonenessLevel(name: "Traditional", celsius: 65, detail: "Familiar texture")
        ], note: "Pasteurize fully — poultry is the reason this app exists."),
        FoodPreset(name: "Chicken thigh", category: "Poultry", shape: .slab, defaultThicknessMM: 30, levels: [
            DonenessLevel(name: "Tender", celsius: 65, detail: "Falls apart"),
            DonenessLevel(name: "Firm", celsius: 74, detail: "Shreddable, fully set")
        ], note: "Higher temps render more connective tissue."),
        FoodPreset(name: "Pork chop", category: "Pork", shape: .slab, defaultThicknessMM: 30, levels: [
            DonenessLevel(name: "Medium-rare", celsius: 58, detail: "Juicy, blush pink"),
            DonenessLevel(name: "Medium", celsius: 62, detail: "Set, tender")
        ], note: "Modern pork is safe at lower temps once pasteurized."),
        FoodPreset(name: "Salmon", category: "Seafood", shape: .slab, defaultThicknessMM: 25, levels: [
            DonenessLevel(name: "Buttery", celsius: 45, detail: "Silky, translucent"),
            DonenessLevel(name: "Tender", celsius: 50, detail: "Just flaking"),
            DonenessLevel(name: "Firm", celsius: 55, detail: "Classic flake")
        ], note: "Cook-and-serve — salmon temps are below pasteurization."),
        FoodPreset(name: "Egg", category: "Egg", shape: .sphere, defaultThicknessMM: 42, levels: [
            DonenessLevel(name: "Onsen", celsius: 63, detail: "Custardy white & yolk"),
            DonenessLevel(name: "Soft", celsius: 64, detail: "Jammy yolk")
        ], note: "Egg curves are famously fussy — a half-degree matters."),
        FoodPreset(name: "Root vegetable", category: "Vegetable", shape: .cylinder, defaultThicknessMM: 30, levels: [
            DonenessLevel(name: "Tender", celsius: 84, detail: "Carrot, beet, potato"),
            DonenessLevel(name: "Fully soft", celsius: 88, detail: "Purée-ready")
        ], note: "Vegetables need ~85°C+ to break down starches.")
    ]

    static var categories: [String] {
        var seen: [String] = []
        for p in presets where !seen.contains(p.category) { seen.append(p.category) }
        return seen
    }
}
