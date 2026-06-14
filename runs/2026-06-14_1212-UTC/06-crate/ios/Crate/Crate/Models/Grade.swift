import SwiftUI

/// Goldmine-standard condition grades for media and sleeve.
/// Stored as rawValue on the model; `rank` gives a 0...100 sortable value.
enum Grade: String, Codable, CaseIterable, Identifiable {
    case mint = "Mint"
    case nearMint = "Near Mint"
    case vgPlus = "Very Good Plus"
    case vg = "Very Good"
    case gPlus = "Good Plus"
    case g = "Good"
    case fair = "Fair"
    case poor = "Poor"

    var id: String { rawValue }

    var display: String { rawValue }

    /// Standard Goldmine abbreviation.
    var abbreviation: String {
        switch self {
        case .mint: return "M"
        case .nearMint: return "NM"
        case .vgPlus: return "VG+"
        case .vg: return "VG"
        case .gPlus: return "G+"
        case .g: return "G"
        case .fair: return "F"
        case .poor: return "P"
        }
    }

    /// Sortable rank, 0 (worst) ... 100 (best).
    var rank: Int {
        switch self {
        case .mint: return 100
        case .nearMint: return 90
        case .vgPlus: return 75
        case .vg: return 60
        case .gPlus: return 45
        case .g: return 30
        case .fair: return 15
        case .poor: return 0
        }
    }

    /// Color tied to grade quality for chips.
    var tint: Color {
        switch self {
        case .mint, .nearMint: return Theme.good
        case .vgPlus, .vg: return Theme.accent
        case .gPlus, .g: return Color.dyn(0xB07A1E, 0xD9AC52)
        case .fair, .poor: return Theme.bad
        }
    }
}
