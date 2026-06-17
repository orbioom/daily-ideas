import SwiftUI

/// Major vs Minor arcana.
enum Arcana: String, CaseIterable, Identifiable, Codable {
    case major = "Major"
    case minor = "Minor"
    var id: String { rawValue }
}

/// The four Minor Arcana suits. Each carries a classical element, color, and emblem.
enum Suit: String, CaseIterable, Identifiable, Codable {
    case wands = "Wands"
    case cups = "Cups"
    case swords = "Swords"
    case pentacles = "Pentacles"

    var id: String { rawValue }

    var element: Element {
        switch self {
        case .wands: return .fire
        case .cups: return .water
        case .swords: return .air
        case .pentacles: return .earth
        }
    }

    /// SF Symbol used as the suit emblem in generated art.
    var symbol: String {
        switch self {
        case .wands: return "flame.fill"
        case .cups: return "drop.fill"
        case .swords: return "burst.fill"
        case .pentacles: return "circle.hexagongrid.fill"
        }
    }

    /// Suit color used to key the generated card art and accents.
    var color: Color {
        switch self {
        case .wands: return Color(hex: 0xD9722E)      // warm amber-fire
        case .cups: return Color(hex: 0x3E8BD6)        // water blue
        case .swords: return Color(hex: 0x8E54C9)      // airy violet
        case .pentacles: return Color(hex: 0x4FA372)   // earthen green
        }
    }
}

/// The four classical elements.
enum Element: String, CaseIterable, Codable {
    case fire = "Fire"
    case water = "Water"
    case air = "Air"
    case earth = "Earth"
    case spirit = "Spirit"   // used for several Major Arcana

    var symbol: String {
        switch self {
        case .fire: return "flame"
        case .water: return "drop"
        case .air: return "wind"
        case .earth: return "leaf"
        case .spirit: return "sparkles"
        }
    }
}

/// One of the 78 Rider–Waite–Smith cards. Pure value type; the full deck is embedded in `Deck`.
struct TarotCard: Identifiable, Hashable {
    let id: Int                 // stable 0...77
    let name: String
    let arcana: Arcana
    let suit: Suit?             // nil for Major Arcana
    let number: Int             // Major: 0...21 ; Minor: 1 (Ace) ... 14 (King)
    let element: Element
    let keywords: [String]
    let upright: String
    let reversed: String

    /// A short numeral shown on the generated art (Roman for Major, rank label for Minor).
    var rankLabel: String {
        switch arcana {
        case .major:
            return TarotCard.roman(number)
        case .minor:
            switch number {
            case 1: return "A"
            case 11: return "P"   // Page
            case 12: return "Kn"  // Knight
            case 13: return "Q"   // Queen
            case 14: return "K"   // King
            default: return String(number)
            }
        }
    }

    /// Human-readable rank name for accessibility and detail copy.
    var rankName: String {
        switch arcana {
        case .major:
            return TarotCard.roman(number)
        case .minor:
            switch number {
            case 1: return "Ace"
            case 11: return "Page"
            case 12: return "Knight"
            case 13: return "Queen"
            case 14: return "King"
            default: return String(number)
            }
        }
    }

    /// Pip count for spot-card art (Ace–10 → 1...10); court & majors return 0 (use emblem instead).
    var pipCount: Int {
        guard arcana == .minor, (1...10).contains(number) else { return 0 }
        return number
    }

    static func roman(_ n: Int) -> String {
        let table: [(Int, String)] = [(1000,"M"),(900,"CM"),(500,"D"),(400,"CD"),
                                       (100,"C"),(90,"XC"),(50,"L"),(40,"XL"),
                                       (10,"X"),(9,"IX"),(5,"V"),(4,"IV"),(1,"I")]
        if n == 0 { return "0" }
        var value = n
        var out = ""
        for (v, s) in table {
            while value >= v {
                out += s
                value -= v
            }
        }
        return out
    }
}
