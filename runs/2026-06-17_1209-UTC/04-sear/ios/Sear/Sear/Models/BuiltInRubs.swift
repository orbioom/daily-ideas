import Foundation

/// A built-in classic rub template (not a SwiftData model). Users can copy one to edit.
struct BuiltInRub: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let ingredients: [String]
    let steps: String
    let notes: String
}

enum BuiltInRubs {
    static let all: [BuiltInRub] = [
        BuiltInRub(
            name: "Classic SPG",
            ingredients: ["Coarse salt — 2 parts",
                          "Coarse black pepper — 2 parts",
                          "Granulated garlic — 1 part"],
            steps: "Mix equal-ish parts and apply heavily. The Texas standard for beef.",
            notes: "Lets the meat speak. Perfect on brisket and beef ribs."),
        BuiltInRub(
            name: "Memphis Dust",
            ingredients: ["Paprika — 4 tbsp",
                          "Brown sugar — 3 tbsp",
                          "Black pepper — 1 tbsp",
                          "Salt — 1 tbsp",
                          "Garlic powder — 1 tbsp",
                          "Onion powder — 1 tbsp",
                          "Ground mustard — 1 tsp",
                          "Cayenne — 1 tsp"],
            steps: "Whisk together and store airtight. Dust ribs the night before.",
            notes: "The dry-rib classic — sweet, savory, a little heat."),
        BuiltInRub(
            name: "Carolina Pork Rub",
            ingredients: ["Brown sugar — 3 tbsp",
                          "Paprika — 2 tbsp",
                          "Salt — 2 tbsp",
                          "Black pepper — 1 tbsp",
                          "Cumin — 1 tsp",
                          "Cayenne — 1 tsp"],
            steps: "Combine and rub onto pork shoulder before an overnight rest.",
            notes: "Pairs with a vinegar mop for pulled pork."),
        BuiltInRub(
            name: "Poultry Seasoning",
            ingredients: ["Salt — 2 tbsp",
                          "Paprika — 1 tbsp",
                          "Garlic powder — 1 tbsp",
                          "Onion powder — 1 tbsp",
                          "Dried thyme — 1 tsp",
                          "Black pepper — 1 tsp",
                          "Baking powder — 1 tsp"],
            steps: "Mix and apply under and over the skin. Baking powder crisps the skin.",
            notes: "Great on wings, thighs and whole birds."),
        BuiltInRub(
            name: "Coffee Chili Rub",
            ingredients: ["Finely ground coffee — 2 tbsp",
                          "Brown sugar — 2 tbsp",
                          "Chili powder — 1 tbsp",
                          "Salt — 1 tbsp",
                          "Smoked paprika — 1 tbsp",
                          "Black pepper — 1 tsp"],
            steps: "Blend and press onto beef. Big crust, deep color.",
            notes: "Bold on tri-tip and steaks; balances the smoke."),
        BuiltInRub(
            name: "Lemon Herb (Fish & Veg)",
            ingredients: ["Salt — 2 tbsp",
                          "Dried oregano — 1 tbsp",
                          "Dried dill — 1 tbsp",
                          "Garlic powder — 1 tbsp",
                          "Lemon zest (dried) — 1 tbsp",
                          "Black pepper — 1 tsp"],
            steps: "Combine and sprinkle lightly over fish or vegetables before grilling.",
            notes: "Bright and delicate — won't overpower seafood.")
    ]

    static func builtIn(named name: String) -> BuiltInRub? {
        all.first { $0.name == name }
    }
}
