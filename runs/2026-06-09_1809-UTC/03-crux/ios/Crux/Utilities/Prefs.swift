import Foundation

/// Central registry of persisted preference keys so view code and the engine
/// agree on a single source of truth.
enum Prefs {
    static let onboarded   = "crux.onboarded"
    static let haptics     = "crux.haptics"
    static let defaultList = "crux.defaultList"     // "today" | "anytime"
    static let firstWeekday = "crux.firstWeekday"   // 1 = Sunday … 2 = Monday
    static let confirmDelete = "crux.confirmDelete" // Bool
    static let reminders   = "crux.reminders"       // Bool
}

/// Where a freshly added quick-task lands by default.
enum DefaultList: String, CaseIterable, Identifiable {
    case today, anytime
    var id: String { rawValue }
    var label: String { self == .today ? "Today" : "Anytime" }
}
