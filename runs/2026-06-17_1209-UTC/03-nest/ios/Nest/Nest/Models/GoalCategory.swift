import SwiftUI

/// Category of a savings goal. Stored as `rawValue` String on `Goal`.
enum GoalCategory: String, CaseIterable, Codable, Identifiable {
    case emergency
    case travel
    case home
    case vehicle
    case gift
    case holiday
    case education
    case retirement
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emergency: return "Emergency"
        case .travel: return "Travel"
        case .home: return "Home"
        case .vehicle: return "Vehicle"
        case .gift: return "Gift"
        case .holiday: return "Holiday"
        case .education: return "Education"
        case .retirement: return "Retirement"
        case .other: return "Other"
        }
    }

    var symbolName: String {
        switch self {
        case .emergency: return "cross.case.fill"
        case .travel: return "airplane"
        case .home: return "house.fill"
        case .vehicle: return "car.fill"
        case .gift: return "gift.fill"
        case .holiday: return "snowflake"
        case .education: return "graduationcap.fill"
        case .retirement: return "beach.umbrella.fill"
        case .other: return "star.fill"
        }
    }

    /// Default swatch hex for charts grouping by category.
    var tintHex: String {
        switch self {
        case .emergency: return "#BE4A33"
        case .travel: return "#3A77B5"
        case .home: return "#2F8F5B"
        case .vehicle: return "#5C6452"
        case .gift: return "#D4567E"
        case .holiday: return "#1FA8A0"
        case .education: return "#9B5DE5"
        case .retirement: return "#C9852A"
        case .other: return "#8B927E"
        }
    }
}
