import Foundation
import SwiftData

enum AccountType: String, Codable, CaseIterable, Identifiable {
    // Assets
    case cash, checking, savings, investment, retirement, property, vehicle, crypto, otherAsset
    // Liabilities
    case creditCard, loan, mortgage, studentLoan, otherDebt

    var id: String { rawValue }

    var isAsset: Bool {
        switch self {
        case .cash, .checking, .savings, .investment, .retirement, .property, .vehicle, .crypto, .otherAsset:
            return true
        default: return false
        }
    }

    var label: String {
        switch self {
        case .cash: return "Cash"
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .investment: return "Investments"
        case .retirement: return "Retirement"
        case .property: return "Property"
        case .vehicle: return "Vehicle"
        case .crypto: return "Crypto"
        case .otherAsset: return "Other asset"
        case .creditCard: return "Credit card"
        case .loan: return "Loan"
        case .mortgage: return "Mortgage"
        case .studentLoan: return "Student loan"
        case .otherDebt: return "Other debt"
        }
    }

    /// Coarse category used for the allocation chart.
    var category: String {
        switch self {
        case .cash, .checking, .savings: return "Cash"
        case .investment, .crypto: return "Investments"
        case .retirement: return "Retirement"
        case .property: return "Real estate"
        case .vehicle: return "Vehicles"
        case .otherAsset: return "Other"
        case .creditCard: return "Credit cards"
        case .loan, .otherDebt: return "Loans"
        case .mortgage: return "Mortgage"
        case .studentLoan: return "Student loans"
        }
    }

    var icon: String {
        switch self {
        case .cash: return "banknote.fill"
        case .checking: return "building.columns.fill"
        case .savings: return "dollarsign.circle.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .retirement: return "figure.walk.circle.fill"
        case .property: return "house.fill"
        case .vehicle: return "car.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .otherAsset: return "shippingbox.fill"
        case .creditCard: return "creditcard.fill"
        case .loan: return "banknote.fill"
        case .mortgage: return "house.lodge.fill"
        case .studentLoan: return "graduationcap.fill"
        case .otherDebt: return "minus.circle.fill"
        }
    }

    static var assetTypes: [AccountType] { allCases.filter { $0.isAsset } }
    static var liabilityTypes: [AccountType] { allCases.filter { !$0.isAsset } }
}

@Model
final class Account {
    var id: UUID
    var name: String
    var typeRaw: String
    var institution: String
    var balance: Double           // assets positive; liabilities stored as positive amount owed
    var includeInNetWorth: Bool
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Int

    init(name: String, type: AccountType, institution: String = "",
         balance: Double, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.institution = institution
        self.balance = max(0, balance)
        self.includeInNetWorth = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sortIndex = sortIndex
    }

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .cash }
        set { typeRaw = newValue.rawValue }
    }
    var isAsset: Bool { type.isAsset }

    /// Signed contribution to net worth.
    var signedValue: Double { isAsset ? balance : -balance }
}

@Model
final class BalanceEntry {
    var id: UUID
    var accountID: UUID
    var date: Date
    var balance: Double

    init(accountID: UUID, balance: Double, date: Date = Date()) {
        self.id = UUID()
        self.accountID = accountID
        self.balance = balance
        self.date = date
    }
}
