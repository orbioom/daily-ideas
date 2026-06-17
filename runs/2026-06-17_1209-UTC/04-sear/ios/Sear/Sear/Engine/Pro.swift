import Foundation

/// Pro entitlement constants and the reasons a paywall can surface.
enum Pro {
    /// One-time unlock price (display only — StoreKit wires in for production).
    static let priceLabel = "$3.99"

    /// Free tier allows a single active (cooking/resting) cook at a time.
    static let freeActiveCookLimit = 1

    /// Free tier allows this many user-created rubs (built-ins are always free).
    static let freeCustomRubLimit = 3
}

/// Why the paywall was shown — drives its copy.
enum PaywallReason: String, Identifiable {
    case secondCook
    case moreRubs
    case advancedGuide
    case reverseSearCalc
    case export
    case general
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .secondCook: return "flame.fill"
        case .moreRubs: return "fork.knife"
        case .advancedGuide: return "thermometer.high"
        case .reverseSearCalc: return "function"
        case .export: return "square.and.arrow.up"
        case .general: return "crown.fill"
        }
    }

    var title: String {
        switch self {
        case .secondCook: return "Run more than one cook"
        case .moreRubs: return "Unlimited rub recipes"
        case .advancedGuide: return "Chef doneness & calculators"
        case .reverseSearCalc: return "Reverse-sear calculator"
        case .export: return "Export your cooks"
        case .general: return "Unlock Sear Pro"
        }
    }

    var blurb: String {
        switch self {
        case .secondCook:
            return "Free tier tracks one live cook at a time. Pro lets you run the brisket and the ribs at once."
        case .moreRubs:
            return "Keep unlimited custom rub recipes. The built-in classics are always free."
        case .advancedGuide:
            return "Unlock chef-level doneness temps and the reverse-sear calculator across the whole guide."
        case .reverseSearCalc:
            return "Dial in low-temp roast then sear timing for an edge-to-edge perfect cook."
        case .export:
            return "Export your full cook log as text to share or back up."
        case .general:
            return "A one-time unlock for the advanced live-fire toolkit."
        }
    }
}
