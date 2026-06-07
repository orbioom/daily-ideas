import Foundation
import SwiftData

/// A fly pattern — a recipe plus how many you have in the box.
@Model
final class Pattern {
    var name: String
    var typeRaw: String
    var hookSizeMin: Int          // numeric hook size (smaller number = larger hook)
    var hookSizeMax: Int
    var difficulty: Int           // 1...5
    var inStock: Int              // count in the fly box
    var imitates: String          // what it imitates, e.g. "Blue Winged Olive"
    var isFavorite: Bool
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \Material.pattern) var materials: [Material]

    init(name: String, type: FlyType = .dry, hookSizeMin: Int = 14, hookSizeMax: Int = 16,
         difficulty: Int = 2, inStock: Int = 0, imitates: String = "",
         isFavorite: Bool = false, notes: String = "") {
        self.name = name
        self.typeRaw = type.rawValue
        self.hookSizeMin = min(hookSizeMin, hookSizeMax)
        self.hookSizeMax = max(hookSizeMin, hookSizeMax)
        self.difficulty = difficulty
        self.inStock = inStock
        self.imitates = imitates
        self.isFavorite = isFavorite
        self.notes = notes
        self.materials = []
    }

    var type: FlyType { FlyType(rawValue: typeRaw) ?? .dry }
    var sizeLabel: String {
        hookSizeMin == hookSizeMax ? "#\(hookSizeMin)" : "#\(hookSizeMin)–\(hookSizeMax)"
    }
    var orderedMaterials: [Material] {
        materials.sorted { $0.part.order < $1.part.order }
    }
    var isLow: Bool { inStock <= 2 }
}

/// One line in a fly's tying recipe.
@Model
final class Material {
    var partRaw: String
    var name: String          // the material, e.g. "Olive dun hackle"
    var detail: String        // color / size note
    var pattern: Pattern?

    init(part: MaterialPart, name: String, detail: String = "") {
        self.partRaw = part.rawValue
        self.name = name
        self.detail = detail
    }

    var part: MaterialPart { MaterialPart(rawValue: partRaw) ?? .body }
}

/// A logged catch.
@Model
final class Catch {
    var date: Date
    var species: String
    var location: String
    var lengthInches: Double
    var waterTempF: Double
    var airTempF: Double
    var weatherRaw: String
    var patternName: String
    var released: Bool
    var notes: String

    init(date: Date = .now, species: String = "", location: String = "",
         lengthInches: Double = 0, waterTempF: Double = 0, airTempF: Double = 0,
         weather: Weather = .partly, patternName: String = "", released: Bool = true,
         notes: String = "") {
        self.date = date
        self.species = species
        self.location = location
        self.lengthInches = lengthInches
        self.waterTempF = waterTempF
        self.airTempF = airTempF
        self.weatherRaw = weather.rawValue
        self.patternName = patternName
        self.released = released
        self.notes = notes
    }

    var weather: Weather { Weather(rawValue: weatherRaw) ?? .partly }
}
