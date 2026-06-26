import SwiftData
import Foundation

// Beer style categories
enum BeerStyle: String, CaseIterable, Codable {
    case ale = "Ale"
    case lager = "Lager"
    case wheat = "Wheat"
    case stout = "Stout"
    case ipa = "IPA"
    case sour = "Sour"
    case porter = "Porter"
    case other = "Other"

    var icon: String {
        switch self {
        case .ale: return "drop.fill"
        case .lager: return "drop.halffull"
        case .wheat: return "sparkles"
        case .stout: return "moon.fill"
        case .ipa: return "leaf.fill"
        case .sour: return "bolt.fill"
        case .porter: return "cloud.fill"
        case .other: return "circle.fill"
        }
    }
}

enum IngredientType: String, CaseIterable, Codable {
    case grain = "Grain"
    case hop = "Hop"
    case yeast = "Yeast"
    case adjunct = "Adjunct"
    case water = "Water Treatment"
    case other = "Other"

    var icon: String {
        switch self {
        case .grain: return "seal.fill"
        case .hop: return "leaf.circle.fill"
        case .yeast: return "bubbles.and.sparkles.fill"
        case .adjunct: return "plus.circle.fill"
        case .water: return "drop.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
final class Recipe {
    var id: UUID
    var name: String
    var beerStyle: String
    var batchSizeLiters: Double
    var originalGravity: Double  // e.g. 1.050
    var finalGravity: Double     // e.g. 1.012
    var ibu: Double              // International Bitterness Units
    var srm: Double              // Color (Standard Reference Method)
    var efficiency: Double       // 0.0 - 1.0 mash efficiency
    var notes: String
    var tags: String             // comma-separated
    var isFavorite: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient]

    @Relationship(deleteRule: .cascade, inverse: \BrewBatch.recipe)
    var batches: [BrewBatch]

    init(
        name: String,
        beerStyle: String = BeerStyle.ale.rawValue,
        batchSizeLiters: Double = 19,
        originalGravity: Double = 1.050,
        finalGravity: Double = 1.012,
        ibu: Double = 30,
        srm: Double = 8,
        efficiency: Double = 0.75,
        notes: String = "",
        tags: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.beerStyle = beerStyle
        self.batchSizeLiters = batchSizeLiters
        self.originalGravity = originalGravity
        self.finalGravity = finalGravity
        self.ibu = ibu
        self.srm = srm
        self.efficiency = efficiency
        self.notes = notes
        self.tags = tags
        self.isFavorite = false
        self.createdAt = Date()
        self.ingredients = []
        self.batches = []
    }

    // ABV = (OG - FG) * 131.25
    var abv: Double {
        (originalGravity - finalGravity) * 131.25
    }

    // BU:GU ratio (balance)
    var buGuRatio: Double {
        let gu = (originalGravity - 1.0) * 1000
        guard gu > 0 else { return 0 }
        return ibu / gu
    }

    var colorDescription: String {
        switch srm {
        case ..<3: return "Pale Straw"
        case 3..<6: return "Gold"
        case 6..<9: return "Amber"
        case 9..<14: return "Copper"
        case 14..<18: return "Brown"
        case 18..<25: return "Dark Brown"
        case 25..<35: return "Very Dark"
        default: return "Black"
        }
    }
}

@Model
final class RecipeIngredient {
    var id: UUID
    var ingredientType: String
    var name: String
    var amountGrams: Double
    var notes: String
    var sortOrder: Int
    var recipe: Recipe?

    // For hops
    var alphaAcidPercent: Double
    var additionMinutes: Int  // minutes before end of boil (60=first addition)

    init(
        ingredientType: String = IngredientType.grain.rawValue,
        name: String,
        amountGrams: Double = 0,
        notes: String = "",
        sortOrder: Int = 0,
        alphaAcidPercent: Double = 0,
        additionMinutes: Int = 60
    ) {
        self.id = UUID()
        self.ingredientType = ingredientType
        self.name = name
        self.amountGrams = amountGrams
        self.notes = notes
        self.sortOrder = sortOrder
        self.alphaAcidPercent = alphaAcidPercent
        self.additionMinutes = additionMinutes
    }

    var displayAmount: String {
        if amountGrams >= 1000 {
            return String(format: "%.2f kg", amountGrams / 1000)
        }
        return String(format: "%.0f g", amountGrams)
    }
}

@Model
final class BrewBatch {
    var id: UUID
    var batchNumber: Int
    var brewDate: Date
    var status: String  // "planned","fermenting","conditioning","kegged","bottled","complete"
    var actualOG: Double
    var actualFG: Double
    var actualVolumeLiters: Double
    var fermentationTempC: Double
    var notes: String
    var pitchDate: Date?
    var packageDate: Date?
    var recipe: Recipe?

    @Relationship(deleteRule: .cascade, inverse: \FermentationLog.batch)
    var fermentationLogs: [FermentationLog]

    init(
        batchNumber: Int,
        brewDate: Date = Date(),
        status: String = "planned",
        actualOG: Double = 0,
        actualFG: Double = 0,
        actualVolumeLiters: Double = 0,
        fermentationTempC: Double = 20,
        notes: String = ""
    ) {
        self.id = UUID()
        self.batchNumber = batchNumber
        self.brewDate = brewDate
        self.status = status
        self.actualOG = actualOG
        self.actualFG = actualFG
        self.actualVolumeLiters = actualVolumeLiters
        self.fermentationTempC = fermentationTempC
        self.notes = notes
        self.fermentationLogs = []
    }

    var actualABV: Double {
        guard actualFG > 0, actualOG > 0 else { return 0 }
        return (actualOG - actualFG) * 131.25
    }

    var statusDisplayName: String {
        switch status {
        case "planned": return "Planned"
        case "fermenting": return "Fermenting"
        case "conditioning": return "Conditioning"
        case "kegged": return "Kegged"
        case "bottled": return "Bottled"
        case "complete": return "Complete"
        default: return status.capitalized
        }
    }

    var statusColor: String {
        switch status {
        case "planned": return "gray"
        case "fermenting": return "blue"
        case "conditioning": return "orange"
        case "kegged", "bottled": return "green"
        case "complete": return "purple"
        default: return "gray"
        }
    }

    var attenuation: Double? {
        guard actualOG > 1.0, actualFG > 1.0 else { return nil }
        let ogPoints = (actualOG - 1.0) * 1000
        let fgPoints = (actualFG - 1.0) * 1000
        return (1.0 - fgPoints / ogPoints) * 100
    }
}

@Model
final class FermentationLog {
    var id: UUID
    var date: Date
    var gravity: Double
    var tempC: Double
    var notes: String
    var batch: BrewBatch?

    init(date: Date = Date(), gravity: Double = 0, tempC: Double = 20, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.gravity = gravity
        self.tempC = tempC
        self.notes = notes
    }
}

@Model
final class KegSettings {
    var id: UUID
    var hasSeenOnboarding: Bool
    var useMetric: Bool  // liters vs gallons
    var useCelsius: Bool
    var hapticsEnabled: Bool
    var breweryName: String

    init() {
        self.id = UUID()
        self.hasSeenOnboarding = false
        self.useMetric = true
        self.useCelsius = true
        self.hapticsEnabled = true
        self.breweryName = "My Brewery"
    }
}
