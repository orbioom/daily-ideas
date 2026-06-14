import Foundation

/// How a routine step completes. Stored as rawValue on `RoutineStep`.
enum StepKind: String, CaseIterable, Identifiable, Codable {
    /// Counts down `durationSec` and auto-advances at zero.
    case timed
    /// Waits for an explicit tap to complete.
    case checkbox

    var id: String { rawValue }

    var label: String {
        switch self {
        case .timed: return "Timed"
        case .checkbox: return "Check off"
        }
    }

    var symbol: String {
        switch self {
        case .timed: return "timer"
        case .checkbox: return "checkmark.circle"
        }
    }
}
