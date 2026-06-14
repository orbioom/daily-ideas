import SwiftUI

/// Classification of a reading relative to the user's target range.
enum GlucoseBand: String, CaseIterable, Identifiable {
    case low = "Low"
    case inRange = "In range"
    case elevated = "Elevated"
    case high = "High"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .low: return Theme.low
        case .inRange: return Theme.inRange
        case .elevated: return Theme.elevated
        case .high: return Theme.high
        }
    }

    var symbol: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .inRange: return "checkmark.circle.fill"
        case .elevated: return "arrow.up.circle"
        case .high: return "exclamationmark.circle.fill"
        }
    }

    /// Classify a canonical mg/dL value against a target range.
    /// "Elevated" is the upper part of-but-still-within tolerance above the high bound,
    /// while values clearly above `high` are "High".
    static func classify(mgdl: Double, low: Double, high: Double) -> GlucoseBand {
        let safeLow = min(low, high)
        let safeHigh = max(low, high)
        if mgdl < safeLow { return .low }
        if mgdl <= safeHigh { return .inRange }
        // Between high and a soft ceiling counts as "elevated"; beyond is "high".
        let elevatedCeiling = safeHigh * 1.4   // e.g. 180 -> 252
        if mgdl <= elevatedCeiling { return .elevated }
        return .high
    }
}
