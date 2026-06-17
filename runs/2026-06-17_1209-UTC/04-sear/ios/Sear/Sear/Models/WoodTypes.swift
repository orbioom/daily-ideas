import Foundation

/// A smoking wood and what it pairs with. Static reference.
struct WoodType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let strength: String        // mild / medium / strong
    let pairsWith: String

    init(_ name: String, _ strength: String, _ pairsWith: String) {
        self.name = name
        self.strength = strength
        self.pairsWith = pairsWith
    }
}

enum WoodTypes {
    static let all: [WoodType] = [
        WoodType("Apple", "Mild, sweet", "Pork, poultry, fish"),
        WoodType("Cherry", "Mild, fruity", "Pork, poultry, beef (adds color)"),
        WoodType("Alder", "Mild, delicate", "Fish, seafood, poultry"),
        WoodType("Pecan", "Medium, nutty", "Pork, poultry, beef"),
        WoodType("Maple", "Mild, sweet", "Poultry, pork, vegetables"),
        WoodType("Oak", "Medium, balanced", "Beef, lamb, brisket"),
        WoodType("Post Oak", "Medium, clean", "Brisket, beef ribs"),
        WoodType("Hickory", "Strong, bacon-y", "Pork, ribs, beef"),
        WoodType("Mesquite", "Strong, earthy", "Beef, lamb (use sparingly)"),
        WoodType("Walnut", "Strong, bitter-sweet", "Red meats (blend it)")
    ]

    static let names: [String] = all.map { $0.name }

    static func wood(named name: String) -> WoodType? {
        all.first { $0.name == name }
    }
}
