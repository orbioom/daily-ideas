import Foundation

/// Grammatical person across both languages. Stored/looked-up by `rawValue`.
enum Person: String, CaseIterable, Identifiable, Codable {
    // Spanish
    case yo
    case tu          // tú
    case elElla      // él/ella/usted
    case nosotros
    case vosotros
    case ellos       // ellos/ellas/ustedes
    // French
    case je
    case tuFr        // tu
    case ilElle      // il/elle/on
    case nous
    case vous
    case ils         // ils/elles

    var id: String { rawValue }

    /// The pronoun shown to the learner.
    var pronoun: String {
        switch self {
        case .yo: return "yo"
        case .tu: return "tú"
        case .elElla: return "él/ella"
        case .nosotros: return "nosotros"
        case .vosotros: return "vosotros"
        case .ellos: return "ellos/ellas"
        case .je: return "je"
        case .tuFr: return "tu"
        case .ilElle: return "il/elle"
        case .nous: return "nous"
        case .vous: return "vous"
        case .ils: return "ils/elles"
        }
    }

    /// Slot index 0...5 within a person set (shared between languages).
    var slot: Int {
        switch self {
        case .yo, .je: return 0
        case .tu, .tuFr: return 1
        case .elElla, .ilElle: return 2
        case .nosotros, .nous: return 3
        case .vosotros, .vous: return 4
        case .ellos, .ils: return 5
        }
    }
}
