import Foundation
import SwiftData

/// Seeds a realistic gear catalog and a sample three-season pack list so the
/// weight breakdown, category chart, and insights are populated on first launch.
enum SampleData {
    static func seed(into context: ModelContext) {
        // (name, brand, category, grams, worn, consumable)
        let defs: [(String, String, GearCategory, Double, Bool, Bool)] = [
            ("Trekking tent", "Zpacks", .shelter, 540, false, false),
            ("Quilt 20°F", "Enlightened", .sleep, 595, false, false),
            ("Sleeping pad", "Therm-a-Rest", .sleep, 354, false, false),
            ("Backpack 50L", "Hyperlite", .pack, 880, false, false),
            ("Down jacket", "Patagonia", .clothing, 295, false, false),
            ("Rain jacket", "Outdoor Research", .clothing, 215, false, false),
            ("Base layer top", "Smartwool", .clothing, 150, true, false),
            ("Hiking shirt", "Patagonia", .clothing, 160, true, false),
            ("Trail runners", "Altra", .clothing, 620, true, false),
            ("Canister stove", "MSR", .cooking, 73, false, false),
            ("Titanium pot 750ml", "Toaks", .cooking, 103, false, false),
            ("Spork", "Sea to Summit", .cooking, 11, false, false),
            ("Water filter", "Sawyer", .water, 85, false, false),
            ("Smart water bottles ×2", "—", .water, 78, false, false),
            ("Headlamp", "Nitecore", .electronics, 50, false, false),
            ("Power bank 10k", "Nitecore", .electronics, 150, false, false),
            ("Phone", "Apple", .electronics, 187, true, false),
            ("First-aid kit", "—", .firstAid, 120, false, false),
            ("3 days food", "—", .food, 1800, false, true),
            ("Water 1L", "—", .water, 1000, false, true),
            ("Fuel canister", "MSR", .cooking, 220, false, true),
        ]
        var items: [GearItem] = []
        for d in defs {
            let g = GearItem(name: d.0, brand: d.1, category: d.2, weightGrams: d.3, isWorn: d.4, isConsumable: d.5)
            context.insert(g)
            items.append(g)
        }

        let list = PackList(name: "3-Season Overnighter", trip: "Sierra · July")
        context.insert(list)
        for g in items {
            let qty = 1
            let e = PackEntry(gear: g, quantity: qty)
            e.packed = !g.isConsumable
            list.entries.append(e)
        }
    }
}
