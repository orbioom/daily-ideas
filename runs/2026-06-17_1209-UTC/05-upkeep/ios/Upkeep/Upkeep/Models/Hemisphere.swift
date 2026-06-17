import Foundation

/// Used to map seasonal cadences to calendar months.
enum Hemisphere: String, CaseIterable, Identifiable {
    case northern
    case southern

    var id: String { rawValue }

    var label: String {
        switch self {
        case .northern: return "Northern"
        case .southern: return "Southern"
        }
    }

    /// Month (1...12) on which the given season starts in this hemisphere.
    func startMonth(for season: Season) -> Int {
        switch self {
        case .northern:
            return season.northernStartMonth
        case .southern:
            // Southern hemisphere seasons are offset by six months.
            let shifted = (season.northernStartMonth + 6 - 1) % 12 + 1
            return shifted
        }
    }
}
