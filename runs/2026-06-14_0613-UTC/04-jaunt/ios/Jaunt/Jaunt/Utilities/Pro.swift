import SwiftUI

/// Pro entitlement and gating policy. One-time unlock, demo only.
enum Pro {
    /// Free tier allows up to this many trips.
    static let freeTripLimit = 2
    static let price = "$4.99"

    /// Whether a new trip may be created given current count and Pro state.
    static func canCreateTrip(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeTripLimit
    }
}

/// Why the paywall was shown — tunes copy and highlighted feature.
enum PaywallReason: Identifiable {
    case tripLimit
    case templates
    case budget
    case export

    var id: String {
        switch self {
        case .tripLimit: return "tripLimit"
        case .templates: return "templates"
        case .budget: return "budget"
        case .export: return "export"
        }
    }

    var headline: String {
        switch self {
        case .tripLimit: return "Plan unlimited trips"
        case .templates: return "Unlock every packing template"
        case .budget: return "See full budget analytics"
        case .export: return "Export your itinerary"
        }
    }

    var detail: String {
        switch self {
        case .tripLimit: return "The free tier keeps \(Pro.freeTripLimit) trips. Go Pro for as many as you like."
        case .templates: return "Beach, City, Business, Camping and Winter starters — all yours with Pro."
        case .budget: return "Category breakdowns and spend insights come with Jaunt Pro."
        case .export: return "Copy a clean day-by-day text plan to share, with Pro."
        }
    }
}
