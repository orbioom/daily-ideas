import SwiftUI

/// Card priority. Stored on `Card` as `priorityRaw` (String) for SwiftData stability.
enum Priority: String, CaseIterable, Identifiable {
    case none = "None"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    /// Sort weight — higher means more urgent.
    var weight: Int {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    var color: Color {
        switch self {
        case .none: return Theme.inkSoft
        case .low: return Theme.good
        case .medium: return Theme.warn
        case .high: return Theme.bad
        }
    }

    var symbol: String {
        switch self {
        case .none: return "minus"
        case .low: return "arrow.down"
        case .medium: return "equal"
        case .high: return "exclamationmark.2"
        }
    }
}
