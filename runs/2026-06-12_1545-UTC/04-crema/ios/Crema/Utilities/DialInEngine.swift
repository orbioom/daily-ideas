import Foundation
import SwiftUI

enum FreshnessState: String {
    case unknown = "No roast date"
    case resting = "Resting"          // degassing, < ~4 days
    case peak = "Peak window"         // sweet spot
    case fading = "Fading"            // past peak
    case stale = "Stale"              // well past peak

    var color: Color {
        switch self {
        case .unknown: return Theme.textSecondary
        case .resting: return Theme.sour
        case .peak: return Theme.balanced
        case .fading: return Theme.crema
        case .stale: return Theme.bitter
        }
    }
    var advice: String {
        switch self {
        case .unknown: return "Add a roast date to track freshness."
        case .resting: return "Still degassing — flavors settle after a few days of rest."
        case .peak: return "In the sweet spot. Brew now for the best cup."
        case .fading: return "Past peak but still good. Brew soon."
        case .stale: return "Well past its prime — expect flatter, duller flavors."
        }
    }
}

/// A dial-in suggestion: a direction plus a human explanation.
struct DialInTip: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let detail: String
    let color: Color
}

enum DialInEngine {

    /// Espresso peaks roughly 4–21 days off roast; filter a touch later. We use
    /// a slightly wider window for filter methods.
    static func freshness(daysSinceRoast days: Int?, espresso: Bool) -> FreshnessState {
        guard let days else { return .unknown }
        if days < 0 { return .unknown }
        let restEnd = espresso ? 4 : 3
        let peakEnd = espresso ? 21 : 28
        let fadeEnd = espresso ? 40 : 50
        if days < restEnd { return .resting }
        if days <= peakEnd { return .peak }
        if days <= fadeEnd { return .fading }
        return .stale
    }

    /// Analyze a logged espresso shot's geometry and surface observations.
    static func extractionTips(for brew: Brew) -> [DialInTip] {
        var tips: [DialInTip] = []
        let ratio = brew.ratio
        let range = brew.method.ratioRange

        if brew.method.isEspresso {
            // Time
            if brew.timeSeconds > 0 {
                if brew.timeSeconds < 22 {
                    tips.append(.init(symbol: "hare.fill", title: "Fast shot",
                                      detail: "\(Int(brew.timeSeconds))s is quick. Grind finer to slow the flow and lift sweetness.",
                                      color: Theme.sour))
                } else if brew.timeSeconds > 34 {
                    tips.append(.init(symbol: "tortoise.fill", title: "Slow shot",
                                      detail: "\(Int(brew.timeSeconds))s is long. Grind coarser to avoid over-extraction and bitterness.",
                                      color: Theme.bitter))
                } else {
                    tips.append(.init(symbol: "checkmark.circle.fill", title: "Good shot time",
                                      detail: "\(Int(brew.timeSeconds))s sits in the classic 25–30s window.",
                                      color: Theme.balanced))
                }
            }
            // Ratio
            if ratio > 0 {
                if ratio < 1.7 {
                    tips.append(.init(symbol: "arrow.down.circle", title: "Tight ratio",
                                      detail: String(format: "%@ is concentrated and ristretto-like — punchy but can taste sharp.", brew.ratioString),
                                      color: Theme.sour))
                } else if ratio > 2.6 {
                    tips.append(.init(symbol: "arrow.up.circle", title: "Long ratio",
                                      detail: String(format: "%@ is a lungo — higher extraction, watch for bitterness.", brew.ratioString),
                                      color: Theme.bitter))
                } else {
                    tips.append(.init(symbol: "scalemass.fill", title: "Balanced ratio",
                                      detail: String(format: "%@ is a classic espresso ratio.", brew.ratioString),
                                      color: Theme.balanced))
                }
            }
        } else {
            if ratio > 0 {
                if ratio < range.lowerBound {
                    tips.append(.init(symbol: "drop.triangle", title: "Strong brew",
                                      detail: String(format: "%@ is stronger than typical for %@.", brew.ratioString, brew.method.rawValue),
                                      color: Theme.bitter))
                } else if ratio > range.upperBound {
                    tips.append(.init(symbol: "drop", title: "Light brew",
                                      detail: String(format: "%@ is more dilute than typical for %@.", brew.ratioString, brew.method.rawValue),
                                      color: Theme.sour))
                } else {
                    tips.append(.init(symbol: "checkmark.circle.fill", title: "Good ratio",
                                      detail: String(format: "%@ is in the typical range for %@.", brew.ratioString, brew.method.rawValue),
                                      color: Theme.balanced))
                }
            }
        }
        return tips
    }

    /// The core dial-in: from a taste outcome, what to change next time.
    static func nextStep(taste: Taste, method: BrewMethod) -> DialInTip {
        switch taste {
        case .sour:
            return method.isEspresso
                ? .init(symbol: "arrow.down.to.line", title: "Grind finer",
                        detail: "Sour means under-extracted. Go a step finer (and/or pull a touch longer / hotter) to draw out sweetness.",
                        color: Theme.sour)
                : .init(symbol: "arrow.down.to.line", title: "Grind finer or brew longer",
                        detail: "Sour means under-extracted. Grind finer, raise water temp, or extend the brew time.",
                        color: Theme.sour)
        case .bitter:
            return method.isEspresso
                ? .init(symbol: "arrow.up.to.line", title: "Grind coarser",
                        detail: "Bitter means over-extracted. Go a step coarser (and/or shorten the shot / lower temp) to pull back.",
                        color: Theme.bitter)
                : .init(symbol: "arrow.up.to.line", title: "Grind coarser or brew shorter",
                        detail: "Bitter means over-extracted. Grind coarser, lower water temp, or shorten the brew.",
                        color: Theme.bitter)
        case .balanced:
            return .init(symbol: "hand.thumbsup.fill", title: "Lock it in",
                         detail: "Balanced — this recipe is dialed in. Note the grind, dose and ratio so you can repeat it.",
                         color: Theme.balanced)
        }
    }

    /// Ratio calculator: given a dose and target ratio, the output/water needed.
    static func output(dose: Double, ratio: Double) -> Double { dose * ratio }
    static func dose(forOutput output: Double, ratio: Double) -> Double {
        ratio > 0 ? output / ratio : 0
    }
}
