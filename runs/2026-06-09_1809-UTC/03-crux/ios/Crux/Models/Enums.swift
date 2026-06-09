import SwiftUI

/// Task priority. `none` is the calm default; higher priorities get a colored
/// flag in lists and sort to the top within a section.
enum Priority: String, CaseIterable, Identifiable, Codable {
    case none, low, medium, high

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:   return "None"
        case .low:    return "Low"
        case .medium: return "Medium"
        case .high:   return "High"
        }
    }

    var symbol: String {
        switch self {
        case .none:   return "flag.slash"
        case .low:    return "flag"
        case .medium: return "flag.fill"
        case .high:   return "flag.fill"
        }
    }

    var tint: Color {
        switch self {
        case .none:   return Brand.text3
        case .low:    return Brand.info
        case .medium: return Brand.warn
        case .high:   return Brand.danger
        }
    }

    /// Sort weight — high priority floats up (larger == more urgent).
    var rank: Int {
        switch self {
        case .none:   return 0
        case .low:    return 1
        case .medium: return 2
        case .high:   return 3
        }
    }
}

/// Recurrence rule for repeating tasks. When a recurring task is completed the
/// engine advances its date to the next occurrence instead of closing it.
enum Recurrence: String, CaseIterable, Identifiable, Codable {
    case none, daily, weekdays, weekly, monthly, yearly, everyN

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none:     return "Never"
        case .daily:    return "Every day"
        case .weekdays: return "Every weekday"
        case .weekly:   return "Every week"
        case .monthly:  return "Every month"
        case .yearly:   return "Every year"
        case .everyN:   return "Every N days"
        }
    }

    var symbol: String {
        switch self {
        case .none:     return "repeat.circle"
        default:        return "repeat"
        }
    }

    var isRepeating: Bool { self != .none }
}
