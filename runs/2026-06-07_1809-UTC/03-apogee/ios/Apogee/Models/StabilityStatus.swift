import SwiftUI

/// Interpretation of a static stability margin (in calibers).
/// Below 1 caliber a rocket tends to be unstable; 1–2 is the sweet spot;
/// 2–3 is firmly stable; above 3 it can weathercock badly (overstable).
enum StabilityStatus {
    case unstable
    case stable
    case stableFirm
    case overstable

    init(caliber: Double) {
        switch caliber {
        case ..<1:   self = .unstable
        case 1..<2:  self = .stable
        case 2..<3:  self = .stableFirm
        default:     self = .overstable
        }
    }

    var label: String {
        switch self {
        case .unstable:   return "Unstable"
        case .stable:     return "Stable"
        case .stableFirm: return "Stable (firm)"
        case .overstable: return "Overstable"
        }
    }

    var color: Color {
        switch self {
        case .unstable:   return Brand.danger
        case .stable:     return Brand.live
        case .stableFirm: return Brand.info
        case .overstable: return Brand.warn
        }
    }

    var advice: String {
        switch self {
        case .unstable:
            return "Move the CG forward (add nose weight) or enlarge the fins before flying."
        case .stable:
            return "Right in the recommended 1–2 caliber range. Good to fly."
        case .stableFirm:
            return "Firmly stable. Expect straight boosts, slightly more weathercocking in wind."
        case .overstable:
            return "Very stable but prone to weathercocking into the wind. Fly on calm days."
        }
    }
}
