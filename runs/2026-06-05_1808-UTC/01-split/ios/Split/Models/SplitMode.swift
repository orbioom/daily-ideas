import Foundation

/// How an expense's amount is divided among its participants.
enum SplitMode: String, CaseIterable, Identifiable, Codable {
    /// Split evenly; rounding remainder distributed by cents deterministically.
    case equal
    /// Each participant has an exact entered amount; must sum to the total.
    case exact
    /// Split by weights (shares); remainder distributed deterministically.
    case shares

    var id: String { rawValue }

    var title: String {
        switch self {
        case .equal:  return "Equally"
        case .exact:  return "Exact amounts"
        case .shares: return "By shares"
        }
    }

    var shortTitle: String {
        switch self {
        case .equal:  return "Equal"
        case .exact:  return "Exact"
        case .shares: return "Shares"
        }
    }

    var symbol: String {
        switch self {
        case .equal:  return "equal.circle"
        case .exact:  return "dollarsign.circle"
        case .shares: return "chart.pie"
        }
    }

    var hint: String {
        switch self {
        case .equal:  return "Everyone selected pays the same share."
        case .exact:  return "Enter exactly what each person owes. Must add up to the total."
        case .shares: return "Give each person a weight. Bigger weight, bigger share."
        }
    }
}
