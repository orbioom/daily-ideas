import Foundation

/// Pro gating. Free core stays fully usable; Pro unlocks advanced programming + analytics + export.
enum Pro {
    /// One-time unlock price for the README + paywall.
    static let priceLabel = "$5.99"

    /// Whether a built-in/custom program can be created given Pro status.
    static func canUse(_ type: ProgramType, isPro: Bool) -> Bool {
        if isPro { return true }
        return !type.requiresPro
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case customBuilder
    case analytics
    case export

    var id: String {
        switch self {
        case .customBuilder: return "customBuilder"
        case .analytics: return "analytics"
        case .export: return "export"
        }
    }

    var symbol: String {
        switch self {
        case .customBuilder: return "slider.horizontal.3"
        case .analytics: return "chart.xyaxis.line"
        case .export: return "square.and.arrow.up"
        }
    }

    var title: String {
        switch self {
        case .customBuilder: return "Build your own program"
        case .analytics: return "Unlock full progress analytics"
        case .export: return "Export your training log"
        }
    }

    var blurb: String {
        switch self {
        case .customBuilder:
            return "Design custom days, exercises, and progression — plus accessory programming on the built-ins."
        case .analytics:
            return "See e1RM trends per lift, volume by muscle group, weekly volume, and your full PR board."
        case .export:
            return "Export every session as CSV or text to back up or analyze elsewhere."
        }
    }
}
