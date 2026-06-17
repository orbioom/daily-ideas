import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can keep up to this many active tasks.
    static let freeActiveTaskLimit = 10

    /// Display price for the one-time unlock.
    static let priceLabel = "$3.99"

    /// Whether a new active task can be added given current count and Pro status.
    static func canAddActiveTask(currentActiveCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentActiveCount < freeActiveTaskLimit
    }

    /// Remaining free active-task slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentActiveCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeActiveTaskLimit - currentActiveCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case taskLimit
    case costTracking
    case forecast
    case reminders
    case export

    var id: String {
        switch self {
        case .taskLimit: return "taskLimit"
        case .costTracking: return "costTracking"
        case .forecast: return "forecast"
        case .reminders: return "reminders"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .taskLimit: return "You've reached the free task limit"
        case .costTracking: return "Track what upkeep costs"
        case .forecast: return "See your cost forecast"
        case .reminders: return "Never miss a due date"
        case .export: return "Export your home log"
        }
    }

    var blurb: String {
        switch self {
        case .taskLimit:
            return "Free Upkeep keeps up to \(Pro.freeActiveTaskLimit) active tasks. Go Pro for an unlimited maintenance plan."
        case .costTracking:
            return "Log actual costs and see total spend by system and by year."
        case .forecast:
            return "Project your upcoming and annual maintenance spend before it hits."
        case .reminders:
            return "Get a calm local reminder when a task is due. Private, on-device."
        case .export:
            return "Export your full task list and completion history as a CSV file."
        }
    }

    var symbol: String {
        switch self {
        case .taskLimit: return "infinity"
        case .costTracking: return "dollarsign.circle.fill"
        case .forecast: return "chart.line.uptrend.xyaxis"
        case .reminders: return "bell.badge.fill"
        case .export: return "square.and.arrow.up"
        }
    }
}
