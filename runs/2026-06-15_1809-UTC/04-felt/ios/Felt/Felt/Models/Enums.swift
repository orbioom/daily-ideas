import SwiftUI

/// Cash game vs tournament. Drives conditional fields and ROI math.
enum SessionFormat: String, Codable, CaseIterable, Identifiable {
    case cash = "Cash"
    case tournament = "Tournament"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .cash: return "dollarsign.circle.fill"
        case .tournament: return "trophy.fill"
        }
    }
}

/// Poker variant played.
enum GameType: String, Codable, CaseIterable, Identifiable {
    case nlhe = "NLHE"
    case plo = "PLO"
    case stud = "Stud"
    case mixed = "Mixed"
    case other = "Other"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .nlhe: return "No-Limit Hold'em"
        case .plo: return "Pot-Limit Omaha"
        case .stud: return "Seven-Card Stud"
        case .mixed: return "Mixed Games"
        case .other: return "Other"
        }
    }
}

/// Bankroll transaction direction.
enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case deposit = "Deposit"
    case withdrawal = "Withdrawal"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .deposit: return "arrow.down.circle.fill"
        case .withdrawal: return "arrow.up.circle.fill"
        }
    }
}
