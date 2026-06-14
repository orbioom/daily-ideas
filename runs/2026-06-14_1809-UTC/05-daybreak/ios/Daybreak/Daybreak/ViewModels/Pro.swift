import Foundation

/// Free-tier limits and Pro gating logic.
enum Pro {
    /// Free users can keep up to this many routines. Pro unlocks unlimited.
    static let freeRoutineLimit = 2

    /// Display price for the one-time unlock.
    static let priceLabel = "$5.99"

    /// Whether a new routine can be created given the current count and Pro status.
    static func canAddRoutine(currentCount: Int, isPro: Bool) -> Bool {
        if isPro { return true }
        return currentCount < freeRoutineLimit
    }

    /// Remaining free routine slots (nil when Pro = unlimited).
    static func remainingFreeSlots(currentCount: Int, isPro: Bool) -> Int? {
        if isPro { return nil }
        return max(freeRoutineLimit - currentCount, 0)
    }
}

/// Reasons the paywall is presented.
enum PaywallReason: Identifiable {
    case routineLimit
    case export

    var id: String {
        switch self {
        case .routineLimit: return "routineLimit"
        case .export: return "export"
        }
    }

    var title: String {
        switch self {
        case .routineLimit: return "Room for more routines"
        case .export: return "Export your progress"
        }
    }

    var blurb: String {
        switch self {
        case .routineLimit:
            return "Free Daybreak keeps up to \(Pro.freeRoutineLimit) routines. Go Pro for unlimited routines and every template."
        case .export:
            return "Save your streaks, minutes, and run history as clean text to keep or share."
        }
    }

    var symbol: String {
        switch self {
        case .routineLimit: return "infinity"
        case .export: return "square.and.arrow.up"
        }
    }
}
