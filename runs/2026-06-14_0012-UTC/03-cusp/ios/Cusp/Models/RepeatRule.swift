import Foundation

/// How an event recurs. Stored as a raw `String` on the model.
enum RepeatRule: String, CaseIterable, Identifiable {
    case none
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:    return "Never"
        case .weekly:  return "Weekly"
        case .monthly: return "Monthly"
        case .yearly:  return "Yearly"
        }
    }

    var symbol: String {
        switch self {
        case .none:    return "minus"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly:  return "repeat"
        }
    }

    var repeats: Bool { self != .none }
}
