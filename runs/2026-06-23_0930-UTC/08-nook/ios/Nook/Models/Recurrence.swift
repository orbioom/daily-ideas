import Foundation

/// How often a maintenance task repeats. Stored as a raw string on the model.
enum Recurrence: String, CaseIterable, Codable, Identifiable {
    case monthly
    case quarterly
    case seasonal
    case semiAnnual
    case annual
    case oneTime

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly:    return "Monthly"
        case .quarterly:  return "Quarterly"
        case .seasonal:   return "Seasonal (4×/yr)"
        case .semiAnnual: return "Twice a year"
        case .annual:     return "Annual"
        case .oneTime:    return "One time"
        }
    }

    var shortLabel: String {
        switch self {
        case .monthly:    return "Monthly"
        case .quarterly:  return "Quarterly"
        case .seasonal:   return "Seasonal"
        case .semiAnnual: return "Twice/yr"
        case .annual:     return "Annual"
        case .oneTime:    return "One time"
        }
    }

    var systemImage: String {
        switch self {
        case .monthly:    return "calendar"
        case .quarterly:  return "calendar.badge.clock"
        case .seasonal:   return "leaf"
        case .semiAnnual: return "calendar.day.timeline.left"
        case .annual:     return "calendar.circle"
        case .oneTime:    return "1.circle"
        }
    }

    /// Advances `date` by one interval of this recurrence using the calendar.
    /// Returns nil for `.oneTime` (a one-time task does not recur).
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        var comps = DateComponents()
        switch self {
        case .monthly:    comps.month = 1
        case .quarterly:  comps.month = 3
        case .seasonal:   comps.month = 3
        case .semiAnnual: comps.month = 6
        case .annual:     comps.year = 1
        case .oneTime:    return nil
        }
        return calendar.date(byAdding: comps, to: date)
    }
}
