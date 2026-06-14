import SwiftUI

/// Which day a week starts on, for the Progress streak/heatmap math.
enum WeekStart: String, CaseIterable, Identifiable {
    case sunday
    case monday
    var id: String { rawValue }

    var label: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        }
    }

    /// Calendar `firstWeekday` value (1 = Sunday, 2 = Monday).
    var firstWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        }
    }
}

/// How "completed" is defined for streak/heatmap logic.
enum CompletionThreshold: String, CaseIterable, Identifiable {
    /// Every step must be done.
    case full
    /// At least 80% of steps done counts as completed.
    case eighty
    var id: String { rawValue }

    var label: String {
        switch self {
        case .full: return "All steps (100%)"
        case .eighty: return "Most steps (80%)"
        }
    }

    /// Minimum completion fraction a run must reach to count.
    var minFraction: Double {
        switch self {
        case .full: return 1.0
        case .eighty: return 0.8
        }
    }
}

/// Persisted preferences that actually change app behavior.
@MainActor
final class AppSettings: ObservableObject {
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("keepAwakeDuringRun") var keepAwakeDuringRun: Bool = true
    @AppStorage("soundCueOnStepChange") var soundCueOnStepChange: Bool = true
    @AppStorage("weekStartRaw") var weekStartRaw: String = WeekStart.monday.rawValue
    @AppStorage("completionThresholdRaw") var completionThresholdRaw: String = CompletionThreshold.full.rawValue

    var weekStart: WeekStart {
        get { WeekStart(rawValue: weekStartRaw) ?? .monday }
        set { weekStartRaw = newValue.rawValue }
    }

    var completionThreshold: CompletionThreshold {
        get { CompletionThreshold(rawValue: completionThresholdRaw) ?? .full }
        set { completionThresholdRaw = newValue.rawValue }
    }

    /// A calendar configured with the user's chosen week start, for stats.
    var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = weekStart.firstWeekday
        return cal
    }
}
