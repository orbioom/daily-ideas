import Foundation

/// How a maintenance task recurs. Persisted as its raw String value.
enum CadenceType: String, CaseIterable, Codable, Identifiable {
    case everyNDays
    case everyNWeeks
    case everyNMonths
    case everyNYears
    case seasonal

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyNDays: return "Days"
        case .everyNWeeks: return "Weeks"
        case .everyNMonths: return "Months"
        case .everyNYears: return "Years"
        case .seasonal: return "Seasonal"
        }
    }

    /// Whether this cadence uses a numeric interval count.
    var usesInterval: Bool { self != .seasonal }

    /// Human description for an interval, e.g. "Every 3 months".
    func describe(interval: Int, season: Season?) -> String {
        switch self {
        case .seasonal:
            return "Every \(season?.label ?? "season")"
        case .everyNDays:
            return interval == 1 ? "Every day" : "Every \(interval) days"
        case .everyNWeeks:
            return interval == 1 ? "Every week" : "Every \(interval) weeks"
        case .everyNMonths:
            return interval == 1 ? "Every month" : "Every \(interval) months"
        case .everyNYears:
            return interval == 1 ? "Every year" : "Every \(interval) years"
        }
    }
}
