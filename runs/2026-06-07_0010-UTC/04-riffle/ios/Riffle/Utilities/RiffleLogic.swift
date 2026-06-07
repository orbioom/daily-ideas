import Foundation

enum FlyType: String, Codable, CaseIterable, Identifiable {
    case dry, nymph, emerger, streamer, wet, terrestrial
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dry: return "Dry"; case .nymph: return "Nymph"; case .emerger: return "Emerger"
        case .streamer: return "Streamer"; case .wet: return "Wet"; case .terrestrial: return "Terrestrial"
        }
    }
    var symbol: String {
        switch self {
        case .dry: return "drop"; case .nymph: return "ant"; case .emerger: return "arrow.up.circle"
        case .streamer: return "fish"; case .wet: return "drop.fill"; case .terrestrial: return "leaf"
        }
    }
}

enum MaterialPart: String, Codable, CaseIterable, Identifiable {
    case hook, thread, bead, tail, body, rib, wing, hackle, head
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    /// Display order on the tying bench.
    var order: Int { MaterialPart.allCases.firstIndex(of: self) ?? 0 }
}

enum Weather: String, Codable, CaseIterable, Identifiable {
    case sunny, partly, overcast, rain, mixed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sunny: return "Sunny"; case .partly: return "Partly cloudy"
        case .overcast: return "Overcast"; case .rain: return "Rain"; case .mixed: return "Mixed"
        }
    }
    var symbol: String {
        switch self {
        case .sunny: return "sun.max"; case .partly: return "cloud.sun"
        case .overcast: return "cloud"; case .rain: return "cloud.rain"; case .mixed: return "cloud.sun.rain"
        }
    }
}

/// A hatch in the reference chart — what's emerging and what matches it.
struct Hatch: Identifiable {
    let id = UUID()
    let name: String
    let order: String          // Mayfly, Caddis, Stonefly, Midge, Terrestrial
    let months: [Int]          // 1...12 active months
    let hookSizes: ClosedRange<Int>
    let matchTypes: [FlyType]
    let note: String

    func isActive(in month: Int) -> Bool { months.contains(month) }
}

/// Static hatch reference. Northern-hemisphere temperate freshwater hatches.
enum HatchCatalog {
    static let all: [Hatch] = [
        Hatch(name: "Blue Winged Olive", order: "Mayfly", months: [3,4,5,9,10,11],
              hookSizes: 16...22, matchTypes: [.dry, .emerger, .nymph],
              note: "Cool, overcast days bring the heaviest BWO emergences."),
        Hatch(name: "Pale Morning Dun", order: "Mayfly", months: [6,7,8],
              hookSizes: 14...18, matchTypes: [.dry, .emerger, .nymph],
              note: "Late-morning emergence on summer tailwaters."),
        Hatch(name: "March Brown", order: "Mayfly", months: [4,5,6],
              hookSizes: 10...14, matchTypes: [.dry, .nymph],
              note: "Sporadic but brings up big fish in spring riffles."),
        Hatch(name: "Trico", order: "Mayfly", months: [7,8,9],
              hookSizes: 20...24, matchTypes: [.dry, .emerger],
              note: "Early-morning spinner falls; tiny imitations only."),
        Hatch(name: "Elk Hair Caddis", order: "Caddis", months: [5,6,7,8,9],
              hookSizes: 12...18, matchTypes: [.dry, .emerger],
              note: "Evening caddis; skitter the fly to provoke takes."),
        Hatch(name: "Golden Stonefly", order: "Stonefly", months: [6,7],
              hookSizes: 6...10, matchTypes: [.nymph, .dry],
              note: "Big nymphs migrate to banks before hatching."),
        Hatch(name: "Salmonfly", order: "Stonefly", months: [5,6],
              hookSizes: 2...8, matchTypes: [.dry, .nymph],
              note: "The big show — huge dries on freestone rivers."),
        Hatch(name: "Midge", order: "Midge", months: [1,2,3,11,12],
              hookSizes: 18...24, matchTypes: [.dry, .emerger, .nymph],
              note: "The winter staple when nothing else is moving."),
        Hatch(name: "Hopper", order: "Terrestrial", months: [7,8,9],
              hookSizes: 6...12, matchTypes: [.terrestrial, .dry],
              note: "Hot, windy afternoons blow hoppers onto the water."),
        Hatch(name: "Ant / Beetle", order: "Terrestrial", months: [6,7,8,9],
              hookSizes: 14...20, matchTypes: [.terrestrial, .dry],
              note: "A reliable searching pattern all summer.")
    ]

    static func active(in month: Int) -> [Hatch] {
        all.filter { $0.isActive(in: month) }
    }
}

/// Pure analysis over the fly box and catch log.
enum RiffleLogic {

    /// Patterns that match a hatch by type overlap and hook-size overlap.
    static func matches(for hatch: Hatch, in patterns: [Pattern]) -> [Pattern] {
        patterns.filter { p in
            let typeMatch = hatch.matchTypes.contains(p.type)
            let sizeOverlap = p.hookSizeMax >= hatch.hookSizes.lowerBound &&
                              p.hookSizeMin <= hatch.hookSizes.upperBound
            return typeMatch && sizeOverlap
        }
    }

    /// The pattern with the most logged catches (the confidence fly).
    static func confidenceFly(patterns: [Pattern], catches: [Catch]) -> (Pattern, Int)? {
        var counts: [String: Int] = [:]
        for c in catches { counts[c.patternName, default: 0] += 1 }
        let best = patterns
            .map { ($0, counts[$0.name] ?? 0) }
            .filter { $0.1 > 0 }
            .max { $0.1 < $1.1 }
        return best
    }

    /// Catches grouped by month index (1...12).
    static func catchesByMonth(_ catches: [Catch]) -> [Int: Int] {
        var out: [Int: Int] = [:]
        for c in catches {
            let m = Calendar.current.component(.month, from: c.date)
            out[m, default: 0] += 1
        }
        return out
    }

    /// Catch count per species, descending.
    static func bySpecies(_ catches: [Catch]) -> [(String, Int)] {
        var counts: [String: Int] = [:]
        for c in catches { counts[c.species, default: 0] += 1 }
        return counts.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    /// Average water temperature across catches that recorded one.
    static func averageWaterTemp(_ catches: [Catch]) -> Double? {
        let temps = catches.compactMap { $0.waterTempF > 0 ? $0.waterTempF : nil }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }
}

/// Unit conversions, honoring the user's preferences.
enum Units {
    static func length(_ inches: Double, metric: Bool) -> String {
        metric ? String(format: "%.1f cm", inches * 2.54)
               : String(format: "%.1f in", inches)
    }
    static func temp(_ fahrenheit: Double, metric: Bool) -> String {
        metric ? String(format: "%.0f°C", (fahrenheit - 32) * 5 / 9)
               : String(format: "%.0f°F", fahrenheit)
    }
}
