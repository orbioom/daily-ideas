import SwiftUI

/// Free-tier limits and Pro gating. Backed by `@AppStorage("isPro")` per the
/// build conventions (StoreKit 2 wires in for production).
enum Pro {
    /// Maximum events allowed without Pro.
    static let freeEventLimit = 5
    /// One-time unlock price label.
    static let priceLabel = "$3.99"
    static let productName = "Cusp Pro"

    /// Whether a new event can be created given the current count.
    static func canCreate(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeEventLimit
    }

    /// Whether a given theme is usable under the current entitlement.
    static func canUse(theme: CardTheme, isPro: Bool) -> Bool {
        isPro || theme.isFree
    }
}

/// Reasons the paywall might be presented, for tailored copy.
enum PaywallReason: Identifiable {
    case eventLimit
    case theme
    case shareCard
    case calendar
    case general

    var id: Int {
        switch self {
        case .eventLimit: return 0
        case .theme: return 1
        case .shareCard: return 2
        case .calendar: return 3
        case .general: return 4
        }
    }

    var headline: String {
        switch self {
        case .eventLimit: return "Track everything you care about"
        case .theme:      return "Unlock every gradient"
        case .shareCard:  return "Share beautiful cards"
        case .calendar:   return "See your year at a glance"
        case .general:    return "Get the most out of Cusp"
        }
    }

    var detail: String {
        switch self {
        case .eventLimit:
            return "You've reached the free limit of \(Pro.freeEventLimit) events. Cusp Pro removes the cap so you can count down to anything."
        case .theme:
            return "This gradient is part of Cusp Pro. Unlock all eight themes for your cards."
        case .shareCard:
            return "Render and share gorgeous countdown cards with Cusp Pro."
        case .calendar:
            return "The month calendar is a Cusp Pro feature. Unlock it to see every event in context."
        case .general:
            return "Unlock unlimited events, every gradient theme, share cards and the calendar."
        }
    }
}
