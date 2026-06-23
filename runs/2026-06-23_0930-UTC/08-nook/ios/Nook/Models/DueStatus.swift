import SwiftUI

/// Bucketed urgency for a task's next-due date.
enum DueStatus: Int, Comparable {
    case overdue = 0
    case dueToday = 1
    case dueSoon = 2
    case upcoming = 3
    case inactive = 4

    static func < (lhs: DueStatus, rhs: DueStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .overdue:  return "Overdue"
        case .dueToday: return "Due today"
        case .dueSoon:  return "Due soon"
        case .upcoming: return "Upcoming"
        case .inactive: return "Paused"
        }
    }

    var color: Color {
        switch self {
        case .overdue:  return Theme.overdue
        case .dueToday: return Theme.due
        case .dueSoon:  return Theme.due
        case .upcoming: return Theme.ok
        case .inactive: return Theme.textSecondary
        }
    }

    var systemImage: String {
        switch self {
        case .overdue:  return "exclamationmark.triangle.fill"
        case .dueToday: return "clock.fill"
        case .dueSoon:  return "clock"
        case .upcoming: return "checkmark.circle"
        case .inactive: return "pause.circle"
        }
    }
}
