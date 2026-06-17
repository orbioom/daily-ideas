import Foundation

/// A recurring billing cadence. `customDays` carries its own interval length.
/// Persisted on the model as a raw String token plus a `customDays` Int.
enum BillingCycle: Equatable, Hashable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case quarterly
    case semiannual
    case annual
    case customDays(Int)

    var id: String { token }

    // MARK: - Raw token (round-trips through SwiftData)

    /// Stable token stored on the model. Custom uses "custom" and the day count
    /// is stored separately in `Subscription.customDays`.
    var token: String {
        switch self {
        case .weekly:      return "weekly"
        case .biweekly:    return "biweekly"
        case .monthly:     return "monthly"
        case .quarterly:   return "quarterly"
        case .semiannual:  return "semiannual"
        case .annual:      return "annual"
        case .customDays:  return "custom"
        }
    }

    /// Reconstructs a cycle from its stored token + custom-day count.
    static func from(token: String, customDays: Int) -> BillingCycle {
        switch token {
        case "weekly":     return .weekly
        case "biweekly":   return .biweekly
        case "monthly":    return .monthly
        case "quarterly":  return .quarterly
        case "semiannual": return .semiannual
        case "annual":     return .annual
        case "custom":     return .customDays(max(1, customDays))
        default:           return .monthly
        }
    }

    /// All non-custom cases for pickers (custom is offered separately).
    static var standardCases: [BillingCycle] {
        [.weekly, .biweekly, .monthly, .quarterly, .semiannual, .annual]
    }

    var label: String {
        switch self {
        case .weekly:               return "Weekly"
        case .biweekly:             return "Every 2 weeks"
        case .monthly:              return "Monthly"
        case .quarterly:            return "Quarterly"
        case .semiannual:           return "Every 6 months"
        case .annual:               return "Yearly"
        case .customDays(let d):    return d == 1 ? "Every day" : "Every \(d) days"
        }
    }

    /// Short noun used after a price, e.g. "$9.99 / mo".
    var shortUnit: String {
        switch self {
        case .weekly:               return "wk"
        case .biweekly:             return "2 wk"
        case .monthly:              return "mo"
        case .quarterly:            return "qtr"
        case .semiannual:           return "6 mo"
        case .annual:               return "yr"
        case .customDays(let d):    return "\(d) d"
        }
    }

    /// SF Symbol used to badge the cadence.
    var symbol: String {
        switch self {
        case .weekly, .biweekly:        return "calendar.day.timeline.left"
        case .monthly:                  return "calendar"
        case .quarterly, .semiannual:   return "calendar.badge.clock"
        case .annual:                   return "calendar.circle"
        case .customDays:               return "clock.arrow.circlepath"
        }
    }
}
