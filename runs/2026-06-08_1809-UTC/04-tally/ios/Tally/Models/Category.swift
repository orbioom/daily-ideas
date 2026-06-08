import SwiftUI

/// Spending and income categories. Stored as raw strings on transactions.
enum Category: String, CaseIterable, Identifiable, Codable {
    // expense
    case groceries, dining, transport, housing, utilities, health
    case shopping, entertainment, travel, education, subscriptions, gifts, fees, other
    // income
    case salary, freelance, refund, interest, otherIncome

    var id: String { rawValue }

    var isIncome: Bool {
        switch self {
        case .salary, .freelance, .refund, .interest, .otherIncome: return true
        default: return false
        }
    }

    static var expenseCases: [Category] { allCases.filter { !$0.isIncome } }
    static var incomeCases: [Category] { allCases.filter { $0.isIncome } }

    var title: String {
        switch self {
        case .groceries: return "Groceries"
        case .dining: return "Dining"
        case .transport: return "Transport"
        case .housing: return "Housing"
        case .utilities: return "Utilities"
        case .health: return "Health"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .travel: return "Travel"
        case .education: return "Education"
        case .subscriptions: return "Subscriptions"
        case .gifts: return "Gifts"
        case .fees: return "Fees"
        case .other: return "Other"
        case .salary: return "Salary"
        case .freelance: return "Freelance"
        case .refund: return "Refund"
        case .interest: return "Interest"
        case .otherIncome: return "Other income"
        }
    }

    var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .dining: return "fork.knife"
        case .transport: return "car.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .health: return "cross.case.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .travel: return "airplane"
        case .education: return "book.fill"
        case .subscriptions: return "repeat"
        case .gifts: return "gift.fill"
        case .fees: return "percent"
        case .other: return "square.grid.2x2"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .refund: return "arrow.uturn.left"
        case .interest: return "chart.line.uptrend.xyaxis"
        case .otherIncome: return "plus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .groceries: return Color(hex: 0x3E9E78)
        case .dining: return Color(hex: 0xC0553E)
        case .transport: return Color(hex: 0x4E6BA8)
        case .housing: return Color(hex: 0x8B6FB0)
        case .utilities: return Color(hex: 0xC08A3E)
        case .health: return Color(hex: 0xC04E7A)
        case .shopping: return Color(hex: 0xB07A8C)
        case .entertainment: return Color(hex: 0x3E8F9E)
        case .travel: return Color(hex: 0x5E63A6)
        case .education: return Color(hex: 0x6E8F3E)
        case .subscriptions: return Color(hex: 0x9E7BA8)
        case .gifts: return Color(hex: 0xC07AA0)
        case .fees: return Color(hex: 0x9E5E5E)
        case .other: return Color(hex: 0x6E7287)
        case .salary, .freelance, .refund, .interest, .otherIncome:
            return Color(hex: 0x4FB98C)
        }
    }
}
