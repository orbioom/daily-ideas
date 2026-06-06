import SwiftUI

/// Domain logic that isn't tied to a single model: queen marking colors,
/// colony health assessment, swarm risk, and mite thresholds.
enum BeeLogic {

    // MARK: - Queen marking color (international standard, by year)

    /// The standard queen-marking color for a given year. Cycle of 5 by last digit.
    static func queenColorName(year: Int) -> String {
        switch year % 10 {
        case 1, 6: return "White"
        case 2, 7: return "Yellow"
        case 3, 8: return "Red"
        case 4, 9: return "Green"
        default:   return "Blue"   // 5, 0
        }
    }
    static func queenColorHex(year: Int) -> UInt32 {
        switch year % 10 {
        case 1, 6: return 0xECEEF2
        case 2, 7: return 0xE6C84F
        case 3, 8: return 0xC0392B
        case 4, 9: return 0x4FB98C
        default:   return 0x5AA9E6
        }
    }

    static let mitesThresholdPer300 = 9   // ~3% infestation — common action threshold

    // MARK: - Colony health

    enum Health: String {
        case strong = "Strong", watch = "Watch", risk = "At risk", unknown = "No data"
        var color: Color {
            switch self {
            case .strong: return Brand.live; case .watch: return Brand.warn
            case .risk: return Brand.danger; case .unknown: return Brand.text3
            }
        }
    }

    /// A coarse health read from a hive's latest inspection and status.
    static func health(for hive: Hive) -> Health {
        if !hive.status.isLive { return .risk }
        guard let i = hive.latestInspection else { return .unknown }
        var score = 0
        if i.queenSeen || i.eggsSeen { score += 1 } else { score -= 2 }
        if i.brood.rawValue >= 3 { score += 1 }
        if i.population.rawValue >= 3 { score += 1 }
        if i.stores.rawValue >= 2 { score += 1 } else { score -= 1 }
        if i.mitesPer300 >= mitesThresholdPer300 { score -= 2 }
        if hive.status == .queenless { score -= 2 }
        if score >= 3 { return .strong }
        if score >= 1 { return .watch }
        return .risk
    }

    /// Swarm risk: live queen cells in a crowded, populous colony.
    static func swarmRisk(for hive: Hive) -> Bool {
        guard let i = hive.latestInspection, hive.status.isLive else { return false }
        return i.queenCells > 0 && (i.space == .crowded || i.population.rawValue >= 4)
    }

    /// Whether the latest mite count is at or over the action threshold.
    static func miteAlert(for hive: Hive) -> Bool {
        guard let i = hive.latestInspection else { return false }
        return i.mitesPer300 >= mitesThresholdPer300
    }

    /// Days since last inspection, or nil if never inspected.
    static func daysSinceInspection(_ hive: Hive) -> Int? {
        guard let i = hive.latestInspection else { return nil }
        return Calendar.current.dateComponents([.day], from: i.date, to: .now).day
    }
}
