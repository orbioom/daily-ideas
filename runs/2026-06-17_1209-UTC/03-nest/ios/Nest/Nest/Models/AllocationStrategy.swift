import Foundation

/// How a lump sum is divided across the chosen goals.
enum AllocationStrategy: String, CaseIterable, Identifiable, Codable {
    case proportionalToNeed
    case evenSplit
    case byPriority

    var id: String { rawValue }

    var title: String {
        switch self {
        case .proportionalToNeed: return "By Need"
        case .evenSplit: return "Even Split"
        case .byPriority: return "By Priority"
        }
    }

    var detail: String {
        switch self {
        case .proportionalToNeed: return "More to goals that have further to go"
        case .evenSplit: return "The same amount to every goal"
        case .byPriority: return "Weighted toward higher-priority goals"
        }
    }

    var symbolName: String {
        switch self {
        case .proportionalToNeed: return "chart.pie.fill"
        case .evenSplit: return "equal.square.fill"
        case .byPriority: return "flag.fill"
        }
    }
}
