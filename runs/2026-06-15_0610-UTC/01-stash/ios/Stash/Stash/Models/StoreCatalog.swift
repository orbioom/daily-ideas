import Foundation

/// A curated, in-code catalog entry for one-tap quick-add. These are generic store
/// archetypes and well-known store *names* with a brand-ish color swatch we generate —
/// no logos or trademarked artwork, just a name + category + color.
struct CatalogStore: Identifiable, Hashable {
    let name: String
    let category: CardCategory
    let colorHex: String
    /// The barcode format most commonly used by this kind of store.
    let suggestedFormat: BarcodeFormat

    var id: String { name }
}

/// The built-in quick-add catalog (~24 entries spanning grocery, pharmacy, coffee,
/// airline, retail, fuel, dining, fitness, and entertainment).
enum StoreCatalog {
    static let all: [CatalogStore] = [
        // Grocery
        CatalogStore(name: "Greenfield Market", category: .grocery, colorHex: "#2E9E6B", suggestedFormat: .ean13),
        CatalogStore(name: "Harbor Foods", category: .grocery, colorHex: "#1F7A8C", suggestedFormat: .ean13),
        CatalogStore(name: "Daily Grocer", category: .grocery, colorHex: "#4C8C2B", suggestedFormat: .code128),
        // Pharmacy
        CatalogStore(name: "WellCare Pharmacy", category: .pharmacy, colorHex: "#C0392B", suggestedFormat: .code128),
        CatalogStore(name: "BlueCross Drugs", category: .pharmacy, colorHex: "#2D6CDF", suggestedFormat: .code128),
        // Coffee
        CatalogStore(name: "Roastery Coffee", category: .coffee, colorHex: "#5B3A29", suggestedFormat: .qr),
        CatalogStore(name: "Morning Bean", category: .coffee, colorHex: "#8A5A2B", suggestedFormat: .qr),
        CatalogStore(name: "Steam & Stir", category: .coffee, colorHex: "#3E2723", suggestedFormat: .code128),
        // Retail
        CatalogStore(name: "Metro Outfitters", category: .retail, colorHex: "#34495E", suggestedFormat: .code128),
        CatalogStore(name: "HomeNest", category: .retail, colorHex: "#C0561E", suggestedFormat: .ean13),
        CatalogStore(name: "GadgetWorks", category: .retail, colorHex: "#2C3E91", suggestedFormat: .code128),
        CatalogStore(name: "Bloom Boutique", category: .retail, colorHex: "#B0306E", suggestedFormat: .qr),
        // Airline
        CatalogStore(name: "SkyHigh Airways", category: .airline, colorHex: "#1A5276", suggestedFormat: .pdf417),
        CatalogStore(name: "Pacific Air", category: .airline, colorHex: "#117864", suggestedFormat: .aztec),
        CatalogStore(name: "Northwind Jet", category: .airline, colorHex: "#5D3F8E", suggestedFormat: .pdf417),
        // Fuel
        CatalogStore(name: "FuelPoint", category: .fuel, colorHex: "#D68910", suggestedFormat: .code128),
        CatalogStore(name: "GreenGas Co.", category: .fuel, colorHex: "#3B7A2E", suggestedFormat: .code128),
        // Dining
        CatalogStore(name: "Trattoria Uno", category: .dining, colorHex: "#922B21", suggestedFormat: .qr),
        CatalogStore(name: "Sushi Lane", category: .dining, colorHex: "#1B2631", suggestedFormat: .qr),
        CatalogStore(name: "Burger Yard", category: .dining, colorHex: "#B7950B", suggestedFormat: .code128),
        // Fitness
        CatalogStore(name: "PulseFit Gym", category: .fitness, colorHex: "#16A085", suggestedFormat: .qr),
        CatalogStore(name: "Summit Climb", category: .fitness, colorHex: "#7D6608", suggestedFormat: .code128),
        // Entertainment
        CatalogStore(name: "Cinematic", category: .entertainment, colorHex: "#6C3483", suggestedFormat: .qr),
        CatalogStore(name: "PlayArcade", category: .entertainment, colorHex: "#283593", suggestedFormat: .qr)
    ]

    /// A small palette of pleasant brand-ish colors offered in the color picker.
    static let palette: [String] = [
        "#128F8A", "#2E9E6B", "#1F7A8C", "#2D6CDF", "#5D3F8E",
        "#6C3483", "#B0306E", "#C0392B", "#D68910", "#B7950B",
        "#5B3A29", "#34495E", "#1B2631", "#16A085", "#922B21"
    ]
}
