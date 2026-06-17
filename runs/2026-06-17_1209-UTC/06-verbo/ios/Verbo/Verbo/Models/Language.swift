import SwiftUI

/// The two languages Verbo trains.
enum Language: String, CaseIterable, Identifiable, Codable {
    case spanish
    case french

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spanish: return "Spanish"
        case .french: return "French"
        }
    }

    var nativeName: String {
        switch self {
        case .spanish: return "Español"
        case .french: return "Français"
        }
    }

    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        }
    }

    /// French is gated behind Pro.
    var requiresPro: Bool { self == .french }

    /// The persons used for conjugation in this language, in canonical order.
    var persons: [Person] {
        switch self {
        case .spanish:
            return [.yo, .tu, .elElla, .nosotros, .vosotros, .ellos]
        case .french:
            return [.je, .tuFr, .ilElle, .nous, .vous, .ils]
        }
    }

    /// Tenses available in this language, in teaching order.
    var tenses: [Tense] {
        switch self {
        case .spanish:
            return [.presente, .preterito, .imperfecto, .futuro, .condicional, .subjuntivo]
        case .french:
            return [.present, .imparfait, .futur, .passeCompose]
        }
    }
}
