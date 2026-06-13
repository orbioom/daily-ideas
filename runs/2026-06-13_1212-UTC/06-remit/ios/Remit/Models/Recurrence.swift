import SwiftUI

/// How often a bill repeats. `oneTime` never rolls forward.
enum Recurrence: String, CaseIterable, Identifiable, Codable {
    case oneTime
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneTime:   return "One-time"
        case .weekly:    return "Weekly"
        case .biweekly:  return "Every 2 weeks"
        case .monthly:   return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly:    return "Yearly"
        }
    }

    /// Short adverb used in rows, e.g. "/mo".
    var shortSuffix: String {
        switch self {
        case .oneTime:   return ""
        case .weekly:    return "/wk"
        case .biweekly:  return "/2wk"
        case .monthly:   return "/mo"
        case .quarterly: return "/qtr"
        case .yearly:    return "/yr"
        }
    }

    /// How many times this recurrence fires per year (for monthly normalisation).
    /// `oneTime` returns 0 — it has no recurring rate.
    var occurrencesPerYear: Double {
        switch self {
        case .oneTime:   return 0
        case .weekly:    return 52
        case .biweekly:  return 26
        case .monthly:   return 12
        case .quarterly: return 4
        case .yearly:    return 1
        }
    }
}

/// The seven bill categories, each with an icon and a tint.
enum Category: String, CaseIterable, Identifiable, Codable {
    case housing
    case utilities
    case subscriptions
    case loans
    case insurance
    case transport
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .housing:       return "Housing"
        case .utilities:     return "Utilities"
        case .subscriptions: return "Subscriptions"
        case .loans:         return "Loans"
        case .insurance:     return "Insurance"
        case .transport:     return "Transport"
        case .other:         return "Other"
        }
    }

    var icon: String {
        switch self {
        case .housing:       return "house.fill"
        case .utilities:     return "bolt.fill"
        case .subscriptions: return "rectangle.stack.fill"
        case .loans:         return "banknote.fill"
        case .insurance:     return "shield.lefthalf.filled"
        case .transport:     return "car.fill"
        case .other:         return "tag.fill"
        }
    }

    var color: Color {
        switch self {
        case .housing:       return Color.dyn(0x2F9E76, 0x49C091)
        case .utilities:     return Color.dyn(0xC98A1E, 0xE0A93F)
        case .subscriptions: return Color.dyn(0x3A6EA5, 0x6FA8DC)
        case .loans:         return Color.dyn(0x8E5BA6, 0xB48ACB)
        case .insurance:     return Color.dyn(0x2C8C8C, 0x4FBDBD)
        case .transport:     return Color.dyn(0xB5663A, 0xD79264)
        case .other:         return Color.dyn(0x6B7A73, 0x9AAAA2)
        }
    }
}
