import SwiftUI

/// Relative hearing bands derived from the app's dB-HL-ish scale.
/// These mirror common audiometric descriptors but are RELATIVE to Hark's uncalibrated screening,
/// not a clinical diagnosis.
enum HearingBand: Int, CaseIterable, Identifiable, Comparable {
    case normal = 0
    case mild
    case moderate
    case moderatelySevere
    case severe

    var id: Int { rawValue }

    static func < (lhs: HearingBand, rhs: HearingBand) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .normal: return "Normal range"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .moderatelySevere: return "Moderately severe"
        case .severe: return "Severe"
        }
    }

    /// Inclusive lower bound (in the app's relative dB scale) for this band.
    var lowerBound: Double {
        switch self {
        case .normal: return 0
        case .mild: return 26
        case .moderate: return 41
        case .moderatelySevere: return 56
        case .severe: return 71
        }
    }

    var upperBound: Double {
        switch self {
        case .normal: return 25
        case .mild: return 40
        case .moderate: return 55
        case .moderatelySevere: return 70
        case .severe: return 120
        }
    }

    var color: Color {
        switch self {
        case .normal: return Theme.good
        case .mild: return Color(hex: 0x7FAE3A)
        case .moderate: return Theme.warn
        case .moderatelySevere: return Color(hex: 0xD27A35)
        case .severe: return Theme.bad
        }
    }

    static func classify(_ level: Double) -> HearingBand {
        for band in HearingBand.allCases.reversed() where level >= band.lowerBound {
            return band
        }
        return .normal
    }

    /// Plain-language, reassuring guidance per band (screening, not diagnosis).
    var plainLanguage: String {
        switch self {
        case .normal:
            return "Your responses suggest hearing in the typical range for this screening."
        case .mild:
            return "You may have missed some of the softest tones. Soft speech or distant voices might occasionally be harder to follow."
        case .moderate:
            return "Several softer tones went unheard. Everyday conversation may take more effort, especially with background noise."
        case .moderatelySevere:
            return "Many tones needed to be fairly loud before you heard them. Following speech without help may be difficult."
        case .severe:
            return "Most tones needed to be quite loud. Consider speaking with a hearing professional about a full evaluation."
        }
    }
}

/// Aggregate analysis for one completed test, per ear.
struct EarAnalysis {
    let ear: Ear
    let thresholds: [Int: Double]
    let pta: Double?
    var band: HearingBand? { pta.map { HearingBand.classify($0) } }
}
