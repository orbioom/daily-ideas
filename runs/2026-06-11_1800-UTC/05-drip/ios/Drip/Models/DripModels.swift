import Foundation
import SwiftData

enum DrinkType: String, Codable, CaseIterable {
    case beer    = "Beer"
    case wine    = "Wine"
    case spirits = "Spirits"
    case cocktail = "Cocktail"
    case cider   = "Cider"
    case other   = "Other"

    var emoji: String {
        switch self {
        case .beer:     return "🍺"
        case .wine:     return "🍷"
        case .spirits:  return "🥃"
        case .cocktail: return "🍸"
        case .cider:    return "🍻"
        case .other:    return "🥤"
        }
    }

    var defaultABV: Double {
        switch self {
        case .beer:     return 5.0
        case .wine:     return 13.0
        case .spirits:  return 40.0
        case .cocktail: return 15.0
        case .cider:    return 5.0
        case .other:    return 5.0
        }
    }

    var defaultVolumeML: Double {
        switch self {
        case .beer:     return 355
        case .wine:     return 150
        case .spirits:  return 44
        case .cocktail: return 200
        case .cider:    return 355
        case .other:    return 200
        }
    }
}

enum DrinkContext: String, Codable, CaseIterable {
    case alone      = "Alone"
    case friends    = "With Friends"
    case family     = "Family"
    case dinner     = "Dinner"
    case work       = "Work Event"
    case party      = "Party"
    case date       = "Date"
    case other      = "Other"

    var emoji: String {
        switch self {
        case .alone:  return "🏠"
        case .friends: return "👥"
        case .family: return "👨‍👩‍👧"
        case .dinner: return "🍽️"
        case .work:   return "💼"
        case .party:  return "🎉"
        case .date:   return "❤️"
        case .other:  return "📍"
        }
    }
}

@Model
final class DrinkEntry {
    var id: UUID
    var date: Date
    var drinkTypeRaw: String
    var name: String
    var abv: Double
    var volumeML: Double
    var contextRaw: String
    var notes: String
    var costAmount: Double

    init(drinkType: DrinkType, name: String = "", abv: Double, volumeML: Double,
         context: DrinkContext = .other, notes: String = "", cost: Double = 0) {
        self.id = UUID()
        self.date = Date()
        self.drinkTypeRaw = drinkType.rawValue
        self.name = name.isEmpty ? drinkType.rawValue : name
        self.abv = abv
        self.volumeML = volumeML
        self.contextRaw = context.rawValue
        self.notes = notes
        self.costAmount = cost
    }

    var drinkType: DrinkType { DrinkType(rawValue: drinkTypeRaw) ?? .other }
    var context: DrinkContext { DrinkContext(rawValue: contextRaw) ?? .other }

    // 1 standard drink (US) = 14g pure alcohol. alcohol density ~0.789 g/mL
    var standardDrinks: Double {
        (volumeML * (abv / 100.0) * 0.789) / 14.0
    }
}

@Model
final class DrinkGoal {
    var weeklyLimit: Int
    var alcoholFreeDaysTarget: Int
    var costPerDrink: Double
    var currencySymbol: String
    var motivations: [String]
    var startDate: Date

    init(weeklyLimit: Int = 14, alcoholFreeDaysTarget: Int = 3,
         costPerDrink: Double = 8.0, currencySymbol: String = "$") {
        self.weeklyLimit = weeklyLimit
        self.alcoholFreeDaysTarget = alcoholFreeDaysTarget
        self.costPerDrink = costPerDrink
        self.currencySymbol = currencySymbol
        self.motivations = []
        self.startDate = Date()
    }
}
