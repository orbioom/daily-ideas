import SwiftUI

/// Perfume concentration, ordered light to heavy. Stored as rawValue.
enum Concentration: String, Codable, CaseIterable, Identifiable {
    case edc = "EDC"        // Eau de Cologne
    case edt = "EDT"        // Eau de Toilette
    case edp = "EDP"        // Eau de Parfum
    case parfum = "Parfum"  // Parfum
    case extrait = "Extrait" // Extrait de Parfum

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .edc: return "Eau de Cologne"
        case .edt: return "Eau de Toilette"
        case .edp: return "Eau de Parfum"
        case .parfum: return "Parfum"
        case .extrait: return "Extrait de Parfum"
        }
    }

    /// Typical wear-time hint shown when the longevity-hints setting is on.
    var longevityHint: String {
        switch self {
        case .edc: return "≈ 2–3 hrs"
        case .edt: return "≈ 3–5 hrs"
        case .edp: return "≈ 5–8 hrs"
        case .parfum: return "≈ 7–10 hrs"
        case .extrait: return "≈ 8–12 hrs"
        }
    }

    /// Sort weight (heavier = larger).
    var weight: Int {
        switch self {
        case .edc: return 0
        case .edt: return 1
        case .edp: return 2
        case .parfum: return 3
        case .extrait: return 4
        }
    }
}
