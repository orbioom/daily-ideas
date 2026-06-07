import Foundation

/// A reference appliance with typical power draw and runtime. Used by the
/// Reference tab to add loads to a system, and by SampleData.
struct CatalogAppliance: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let watts: Double
    let typicalHoursPerDay: Double
    let category: LoadCategory
    let isAC: Bool

    /// Build a fresh `Load` from this template, ready to attach to a system.
    func makeLoad(quantity: Int = 1) -> Load {
        Load(
            name: name,
            watts: watts,
            hoursPerDay: typicalHoursPerDay,
            quantity: quantity,
            category: category,
            isAC: isAC
        )
    }
}

/// ~20 common off-grid appliances. Wattages reflect real-world vanlife / RV gear.
enum ApplianceCatalog {
    static let all: [CatalogAppliance] = [
        // Refrigeration
        CatalogAppliance(name: "12V Compressor Fridge", watts: 45,  typicalHoursPerDay: 12,  category: .refrigeration, isAC: false),
        CatalogAppliance(name: "Chest Freezer (12V)",   watts: 55,  typicalHoursPerDay: 10,  category: .refrigeration, isAC: false),

        // Climate
        CatalogAppliance(name: "MaxxFan Roof Vent",     watts: 30,  typicalHoursPerDay: 6,   category: .climate, isAC: false),
        CatalogAppliance(name: "Diesel Heater",         watts: 30,  typicalHoursPerDay: 5,   category: .climate, isAC: false),
        CatalogAppliance(name: "Electric Blanket",      watts: 60,  typicalHoursPerDay: 3,   category: .climate, isAC: false),
        CatalogAppliance(name: "12V Heated Mattress",   watts: 45,  typicalHoursPerDay: 4,   category: .climate, isAC: false),

        // Lighting
        CatalogAppliance(name: "LED Cabin Lights",      watts: 15,  typicalHoursPerDay: 5,   category: .lighting, isAC: false),
        CatalogAppliance(name: "LED Strip / Mood",      watts: 8,   typicalHoursPerDay: 3,   category: .lighting, isAC: false),
        CatalogAppliance(name: "Awning Light",          watts: 10,  typicalHoursPerDay: 2,   category: .lighting, isAC: false),

        // Electronics
        CatalogAppliance(name: "Laptop Charge",         watts: 60,  typicalHoursPerDay: 4,   category: .electronics, isAC: false),
        CatalogAppliance(name: "Phone Charge",          watts: 10,  typicalHoursPerDay: 2,   category: .electronics, isAC: false),
        CatalogAppliance(name: "Starlink Mini",         watts: 50,  typicalHoursPerDay: 8,   category: .electronics, isAC: false),
        CatalogAppliance(name: "Wi-Fi Router / Cell",   watts: 12,  typicalHoursPerDay: 12,  category: .electronics, isAC: false),
        CatalogAppliance(name: "12V TV",                watts: 35,  typicalHoursPerDay: 3,   category: .electronics, isAC: false),
        CatalogAppliance(name: "Camera / Drone Charge", watts: 25,  typicalHoursPerDay: 1,   category: .electronics, isAC: false),

        // Water
        CatalogAppliance(name: "Water Pump",            watts: 50,  typicalHoursPerDay: 0.3, category: .water, isAC: false),
        CatalogAppliance(name: "Diesel Water Heater",   watts: 40,  typicalHoursPerDay: 0.5, category: .water, isAC: false),

        // Kitchen (AC through inverter)
        CatalogAppliance(name: "Induction Cooktop",     watts: 1500, typicalHoursPerDay: 0.3, category: .kitchen, isAC: true),
        CatalogAppliance(name: "Microwave",             watts: 1000, typicalHoursPerDay: 0.1, category: .kitchen, isAC: true),
        CatalogAppliance(name: "Electric Kettle",       watts: 1200, typicalHoursPerDay: 0.15, category: .kitchen, isAC: true),
        CatalogAppliance(name: "Coffee Grinder",        watts: 150,  typicalHoursPerDay: 0.05, category: .kitchen, isAC: true),
        CatalogAppliance(name: "Blender",               watts: 400,  typicalHoursPerDay: 0.05, category: .kitchen, isAC: true),

        // Other
        CatalogAppliance(name: "12V Air Compressor",    watts: 120,  typicalHoursPerDay: 0.1, category: .other, isAC: false),
        CatalogAppliance(name: "Power Tool Charger",    watts: 90,   typicalHoursPerDay: 0.3, category: .other, isAC: true)
    ]

    static var byCategory: [(category: LoadCategory, items: [CatalogAppliance])] {
        LoadCategory.allCases.compactMap { cat in
            let items = all.filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    /// Look up a template by name (used when seeding sample data).
    static func appliance(_ name: String) -> CatalogAppliance? {
        all.first { $0.name == name }
    }
}
