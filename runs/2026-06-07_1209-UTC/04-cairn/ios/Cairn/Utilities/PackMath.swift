import Foundation

/// The standard ultralight weight breakdown for a pack list.
struct PackWeights {
    var base: Double = 0        // gear carried, excluding worn & consumables
    var consumable: Double = 0  // food, water, fuel
    var worn: Double = 0        // worn/carried on body
    var totalPack: Double { base + consumable }   // what's on your back
    var skinOut: Double { base + consumable + worn }  // everything you leave with
    var bigThree: Double = 0    // shelter + sleep + pack (subset of base)
}

/// Pure weight math over pack-list entries.
enum PackMath {

    static func weights(for entries: [PackEntry]) -> PackWeights {
        var w = PackWeights()
        for e in entries {
            guard let g = e.gear else { continue }
            let line = e.lineWeight
            if g.isWorn { w.worn += line }
            else if g.isConsumable { w.consumable += line }
            else {
                w.base += line
                if GearCategory.bigThree.contains(g.category) { w.bigThree += line }
            }
        }
        return w
    }

    /// Weight by category across all (non-worn) entries — for the breakdown chart.
    static func byCategory(_ entries: [PackEntry]) -> [(category: GearCategory, grams: Double)] {
        var map: [GearCategory: Double] = [:]
        for e in entries {
            guard let g = e.gear, !g.isWorn else { continue }
            map[g.category, default: 0] += e.lineWeight
        }
        return GearCategory.allCases.compactMap { c in
            guard let g = map[c], g > 0 else { return nil }
            return (c, g)
        }.sorted { $0.grams > $1.grams }
    }

    /// The heaviest individual entries (by line weight).
    static func heaviest(_ entries: [PackEntry], limit: Int = 5) -> [PackEntry] {
        entries.filter { ($0.gear?.weightGrams ?? 0) > 0 }
            .sorted { $0.lineWeight > $1.lineWeight }
            .prefix(limit).map { $0 }
    }

    static func itemCount(_ entries: [PackEntry]) -> Int {
        entries.reduce(0) { $0 + max(1, $1.quantity) }
    }

    /// A qualitative tier for a base weight in grams.
    static func tier(baseGrams: Double) -> String {
        let lbs = baseGrams / 453.592
        switch lbs {
        case ..<5: return "Super-ultralight"
        case ..<10: return "Ultralight"
        case ..<15: return "Lightweight"
        case ..<20: return "Traditional"
        default: return "Heavy"
        }
    }
}

/// Weight unit conversion + formatting.
enum WeightFmt {
    static func string(_ grams: Double, unit: String) -> String {
        switch unit {
        case "oz":
            return String(format: "%.1f oz", grams / 28.3495)
        case "lboz":
            let totalOz = grams / 28.3495
            let lb = Int(totalOz / 16)
            let oz = totalOz - Double(lb) * 16
            if lb > 0 { return String(format: "%dlb %.1foz", lb, oz) }
            return String(format: "%.1f oz", oz)
        case "kg":
            return grams >= 1000 ? String(format: "%.2f kg", grams / 1000) : String(format: "%.0f g", grams)
        default: // grams
            return grams >= 1000 ? String(format: "%.2f kg", grams / 1000) : String(format: "%.0f g", grams)
        }
    }
    /// Compact form for tiles.
    static func compact(_ grams: Double, unit: String) -> String { string(grams, unit: unit) }
}
