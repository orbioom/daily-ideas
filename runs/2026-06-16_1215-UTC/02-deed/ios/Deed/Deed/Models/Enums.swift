import SwiftUI

enum PropertyType: String, CaseIterable, Identifiable, Codable {
    case singleFamily = "Single Family"
    case condo = "Condo"
    case duplex = "Duplex"
    case multiFamily = "Multi-Family"
    case commercial = "Commercial"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .singleFamily: return "house.fill"
        case .condo: return "building.fill"
        case .duplex: return "house.lodge.fill"
        case .multiFamily: return "building.2.fill"
        case .commercial: return "building.columns.fill"
        }
    }
}

enum UnitStatus: String, CaseIterable, Identifiable, Codable {
    case occupied = "Occupied"
    case vacant = "Vacant"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .occupied: return Theme.good
        case .vacant: return Theme.warn
        }
    }
}

enum TxnKind: String, CaseIterable, Identifiable, Codable {
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .income: return Theme.good
        case .expense: return Theme.bad
        }
    }

    var systemImage: String {
        switch self {
        case .income: return "arrow.down.circle.fill"
        case .expense: return "arrow.up.circle.fill"
        }
    }
}

enum TxnCategory: String, CaseIterable, Identifiable, Codable {
    case rent = "Rent"
    case lateFee = "Late Fee"
    case deposit = "Deposit"
    case mortgageInterest = "Mortgage Interest"
    case repairs = "Repairs"
    case maintenance = "Maintenance"
    case propertyTax = "Property Tax"
    case insurance = "Insurance"
    case utilities = "Utilities"
    case management = "Management"
    case hoa = "HOA"
    case capex = "CapEx"
    case other = "Other"

    var id: String { rawValue }

    var kind: TxnKind {
        switch self {
        case .rent, .lateFee, .deposit: return .income
        default: return .expense
        }
    }

    /// CapEx is excluded from operating expenses (used in NOI).
    var isOperatingExpense: Bool {
        switch self {
        case .repairs, .maintenance, .propertyTax, .insurance, .utilities, .management, .hoa, .other:
            return true
        default:
            return false
        }
    }

    var isCapEx: Bool { self == .capex }

    var systemImage: String {
        switch self {
        case .rent: return "dollarsign.circle.fill"
        case .lateFee: return "exclamationmark.circle.fill"
        case .deposit: return "lock.shield.fill"
        case .mortgageInterest: return "percent"
        case .repairs: return "wrench.and.screwdriver.fill"
        case .maintenance: return "paintbrush.fill"
        case .propertyTax: return "building.columns.fill"
        case .insurance: return "shield.lefthalf.filled"
        case .utilities: return "bolt.fill"
        case .management: return "person.2.fill"
        case .hoa: return "house.and.flag.fill"
        case .capex: return "hammer.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    static var incomeCategories: [TxnCategory] { allCases.filter { $0.kind == .income } }
    static var expenseCategories: [TxnCategory] { allCases.filter { $0.kind == .expense } }
}

enum RentStatus: String, CaseIterable, Identifiable, Codable {
    case paid = "Paid"
    case partial = "Partial"
    case unpaid = "Unpaid"
    case late = "Late"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .paid: return Theme.good
        case .partial: return Theme.warn
        case .unpaid: return Theme.inkSoft
        case .late: return Theme.bad
        }
    }

    var systemImage: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .unpaid: return "circle"
        case .late: return "exclamationmark.triangle.fill"
        }
    }
}
