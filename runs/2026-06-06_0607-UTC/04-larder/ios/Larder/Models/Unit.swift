import Foundation

/// Units of measure for a pantry quantity. Stored on `Item` by raw value so the
/// schema is stable. Grouped loosely (count / weight / volume) for the picker.
enum Unit: String, CaseIterable, Identifiable, Codable {
    case piece, pack, can, bottle, jar, box, bag
    case gram, kilogram, ounce, pound
    case milliliter, liter, cup, tablespoon, teaspoon

    var id: String { rawValue }

    /// Short label shown next to a quantity (e.g. "2 pcs").
    var short: String {
        switch self {
        case .piece:      return "pcs"
        case .pack:       return "pack"
        case .can:        return "can"
        case .bottle:     return "btl"
        case .jar:        return "jar"
        case .box:        return "box"
        case .bag:        return "bag"
        case .gram:       return "g"
        case .kilogram:   return "kg"
        case .ounce:      return "oz"
        case .pound:      return "lb"
        case .milliliter: return "ml"
        case .liter:      return "L"
        case .cup:        return "cup"
        case .tablespoon: return "tbsp"
        case .teaspoon:   return "tsp"
        }
    }

    /// Full spoken/written name, used for VoiceOver and the editor picker.
    var fullName: String {
        switch self {
        case .piece:      return "Pieces"
        case .pack:       return "Packs"
        case .can:        return "Cans"
        case .bottle:     return "Bottles"
        case .jar:        return "Jars"
        case .box:        return "Boxes"
        case .bag:        return "Bags"
        case .gram:       return "Grams"
        case .kilogram:   return "Kilograms"
        case .ounce:      return "Ounces"
        case .pound:      return "Pounds"
        case .milliliter: return "Milliliters"
        case .liter:      return "Liters"
        case .cup:        return "Cups"
        case .tablespoon: return "Tablespoons"
        case .teaspoon:   return "Teaspoons"
        }
    }

    enum Family: String, CaseIterable, Identifiable {
        case count = "Count"
        case weight = "Weight"
        case volume = "Volume"
        var id: String { rawValue }
    }

    var family: Family {
        switch self {
        case .piece, .pack, .can, .bottle, .jar, .box, .bag:
            return .count
        case .gram, .kilogram, .ounce, .pound:
            return .weight
        case .milliliter, .liter, .cup, .tablespoon, .teaspoon:
            return .volume
        }
    }

    static func units(in family: Family) -> [Unit] {
        allCases.filter { $0.family == family }
    }

    /// Formats a quantity with this unit, trimming a trailing ".0" for whole numbers.
    func format(_ quantity: Double) -> String {
        let rounded = (quantity * 100).rounded() / 100
        let number: String
        if rounded == rounded.rounded() {
            number = String(Int(rounded))
        } else {
            number = String(format: "%g", rounded)
        }
        return "\(number) \(short)"
    }
}
