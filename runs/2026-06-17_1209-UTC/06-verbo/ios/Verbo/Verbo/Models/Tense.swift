import Foundation

/// Verb tenses across both languages. Stored/looked-up by `rawValue`.
enum Tense: String, CaseIterable, Identifiable, Codable {
    // Spanish
    case presente
    case preterito       // pretérito indefinido
    case imperfecto
    case futuro
    case condicional
    case subjuntivo      // presente de subjuntivo
    // French
    case present
    case imparfait
    case futur           // futur simple
    case passeCompose    // passé composé

    var id: String { rawValue }

    var language: Language {
        switch self {
        case .presente, .preterito, .imperfecto, .futuro, .condicional, .subjuntivo:
            return .spanish
        case .present, .imparfait, .futur, .passeCompose:
            return .french
        }
    }

    /// Display name with proper accents.
    var displayName: String {
        switch self {
        case .presente: return "Presente"
        case .preterito: return "Pretérito"
        case .imperfecto: return "Imperfecto"
        case .futuro: return "Futuro"
        case .condicional: return "Condicional"
        case .subjuntivo: return "Subjuntivo"
        case .present: return "Présent"
        case .imparfait: return "Imparfait"
        case .futur: return "Futur simple"
        case .passeCompose: return "Passé composé"
        }
    }

    /// Short English gloss.
    var englishName: String {
        switch self {
        case .presente, .present: return "Present"
        case .preterito: return "Preterite (simple past)"
        case .imperfecto, .imparfait: return "Imperfect"
        case .futuro, .futur: return "Future"
        case .condicional: return "Conditional"
        case .subjuntivo: return "Present subjunctive"
        case .passeCompose: return "Compound past (perfect)"
        }
    }

    /// Tenses that are part of Pro (advanced).
    var requiresPro: Bool {
        switch self {
        case .condicional, .subjuntivo, .passeCompose: return true
        default: return false
        }
    }

    /// The four "core" Spanish tenses are always free.
    static var freeSpanishTenses: [Tense] {
        [.presente, .preterito, .imperfecto, .futuro]
    }
}
