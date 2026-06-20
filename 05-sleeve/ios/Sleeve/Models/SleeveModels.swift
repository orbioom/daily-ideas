import Foundation
import SwiftData

// MARK: - Enums

enum CardGame: String, CaseIterable, Codable, Identifiable {
    case pokemon  = "Pokémon"
    case magic    = "Magic: The Gathering"
    case yugioh   = "Yu-Gi-Oh!"
    case sports   = "Sports Cards"
    case other    = "Other"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .pokemon: return "⚡"
        case .magic:   return "✨"
        case .yugioh:  return "🌀"
        case .sports:  return "🏆"
        case .other:   return "🃏"
        }
    }

    var formats: [String] {
        switch self {
        case .magic:
            return ["Standard", "Modern", "Legacy", "Commander", "Draft", "Pioneer", "Vintage"]
        case .pokemon:
            return ["Standard", "Expanded", "Unlimited"]
        case .yugioh:
            return ["Advanced", "Traditional", "Speed Duel"]
        case .sports:
            return ["Base Set", "Rookie", "Autograph", "Parallel"]
        case .other:
            return ["Custom"]
        }
    }
}

enum CardRarity: String, CaseIterable, Codable, Identifiable {
    case common      = "Common"
    case uncommon    = "Uncommon"
    case rare        = "Rare"
    case ultraRare   = "Ultra Rare"
    case secret      = "Secret Rare"
    var id: String { rawValue }
}

enum CardCondition: String, CaseIterable, Codable, Identifiable {
    case mint              = "Mint"
    case nearMint          = "Near Mint"
    case lightlyPlayed     = "Lightly Played"
    case moderatelyPlayed  = "Moderately Played"
    case heavilyPlayed     = "Heavily Played"
    case damaged           = "Damaged"
    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .mint:              return "M"
        case .nearMint:          return "NM"
        case .lightlyPlayed:     return "LP"
        case .moderatelyPlayed:  return "MP"
        case .heavilyPlayed:     return "HP"
        case .damaged:           return "D"
        }
    }
}

// MARK: - Models

@Model final class Card {
    var name: String
    var setName: String
    var cardNumber: String
    var game: String
    var rarity: String
    var condition: String
    var quantity: Int
    var estimatedValue: Double
    var isFoil: Bool
    var isGraded: Bool
    var gradeScore: String
    var notes: String
    var addedDate: Date
    var imageData: Data?

    init(
        name: String = "",
        setName: String = "",
        cardNumber: String = "",
        game: String = CardGame.pokemon.rawValue,
        rarity: String = CardRarity.common.rawValue,
        condition: String = CardCondition.nearMint.rawValue,
        quantity: Int = 1,
        estimatedValue: Double = 0.0,
        isFoil: Bool = false,
        isGraded: Bool = false,
        gradeScore: String = "",
        notes: String = "",
        addedDate: Date = .now,
        imageData: Data? = nil
    ) {
        self.name = name
        self.setName = setName
        self.cardNumber = cardNumber
        self.game = game
        self.rarity = rarity
        self.condition = condition
        self.quantity = quantity
        self.estimatedValue = estimatedValue
        self.isFoil = isFoil
        self.isGraded = isGraded
        self.gradeScore = gradeScore
        self.notes = notes
        self.addedDate = addedDate
        self.imageData = imageData
    }

    var totalValue: Double { estimatedValue * Double(quantity) }
    var rarityEnum: CardRarity? { CardRarity(rawValue: rarity) }
    var conditionEnum: CardCondition? { CardCondition(rawValue: condition) }
    var gameEnum: CardGame? { CardGame(rawValue: game) }
}

@Model final class Deck {
    var name: String
    var game: String
    var format: String
    var notes: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var entries: [DeckEntry] = []

    init(
        name: String = "",
        game: String = CardGame.pokemon.rawValue,
        format: String = "Standard",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.name = name
        self.game = game
        self.format = format
        self.notes = notes
        self.createdAt = createdAt
    }

    var cardCount: Int { entries.reduce(0) { $0 + $1.quantity } }
    var gameEnum: CardGame? { CardGame(rawValue: game) }
}

@Model final class DeckEntry {
    var cardId: PersistentIdentifier?
    var cardName: String
    var quantity: Int
    var deck: Deck?

    init(card: Card, quantity: Int = 1) {
        self.cardId = card.persistentModelID
        self.cardName = card.name
        self.quantity = quantity
    }

    init(cardName: String, quantity: Int = 1) {
        self.cardId = nil
        self.cardName = cardName
        self.quantity = quantity
    }
}

@Model final class WantCard {
    var name: String
    var setName: String
    var game: String
    var rarity: String
    var maxPrice: Double
    var priority: Int
    var notes: String
    var addedDate: Date
    var isAcquired: Bool

    init(
        name: String = "",
        setName: String = "",
        game: String = CardGame.pokemon.rawValue,
        rarity: String = CardRarity.common.rawValue,
        maxPrice: Double = 0.0,
        priority: Int = 2,
        notes: String = "",
        addedDate: Date = .now,
        isAcquired: Bool = false
    ) {
        self.name = name
        self.setName = setName
        self.game = game
        self.rarity = rarity
        self.maxPrice = maxPrice
        self.priority = priority
        self.notes = notes
        self.addedDate = addedDate
        self.isAcquired = isAcquired
    }

    var priorityLabel: String {
        switch priority {
        case 3: return "High"
        case 2: return "Medium"
        default: return "Low"
        }
    }

    var priorityIcon: String {
        switch priority {
        case 3: return "🔴"
        case 2: return "🟡"
        default: return "🟢"
        }
    }

    var gameEnum: CardGame? { CardGame(rawValue: game) }
}
