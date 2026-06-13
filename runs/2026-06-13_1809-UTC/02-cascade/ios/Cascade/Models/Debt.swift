import Foundation
import SwiftData
import SwiftUI

enum DebtKind: String, Codable, CaseIterable, Identifiable {
    case creditCard, personalLoan, studentLoan, autoLoan, medical, mortgage, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .creditCard: return "Credit card"
        case .personalLoan: return "Personal loan"
        case .studentLoan: return "Student loan"
        case .autoLoan: return "Auto loan"
        case .medical: return "Medical"
        case .mortgage: return "Mortgage"
        case .other: return "Other"
        }
    }
    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .personalLoan: return "banknote.fill"
        case .studentLoan: return "graduationcap.fill"
        case .autoLoan: return "car.fill"
        case .medical: return "cross.case.fill"
        case .mortgage: return "house.fill"
        case .other: return "tag.fill"
        }
    }
}

@Model
final class Debt {
    var id: UUID
    var name: String
    var kindRaw: String
    var balance: Double          // current principal owed
    var startingBalance: Double  // when first added — used for progress
    var apr: Double              // annual percentage rate, e.g. 19.99
    var minimumPayment: Double
    var createdAt: Date
    var sortIndex: Int           // manual order for the custom strategy

    init(name: String, kind: DebtKind, balance: Double, apr: Double,
         minimumPayment: Double, sortIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.kindRaw = kind.rawValue
        self.balance = max(0, balance)
        self.startingBalance = max(0, balance)
        self.apr = max(0, apr)
        self.minimumPayment = max(0, minimumPayment)
        self.createdAt = Date()
        self.sortIndex = sortIndex
    }

    var kind: DebtKind {
        get { DebtKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    /// Monthly interest accrued at the current balance.
    var monthlyInterest: Double { balance * apr / 1200.0 }

    /// Fraction paid off (0…1) relative to the starting balance.
    var progress: Double {
        guard startingBalance > 0 else { return balance <= 0 ? 1 : 0 }
        return min(1, max(0, 1 - balance / startingBalance))
    }

    var snapshot: DebtSnapshot {
        DebtSnapshot(id: id, name: name, balance: balance,
                     apr: apr, minimum: minimumPayment, sortIndex: sortIndex)
    }
}

@Model
final class PaymentLog {
    var id: UUID
    var debtID: UUID
    var debtName: String
    var amount: Double
    var date: Date
    var balanceAfter: Double

    init(debtID: UUID, debtName: String, amount: Double, balanceAfter: Double, date: Date = Date()) {
        self.id = UUID()
        self.debtID = debtID
        self.debtName = debtName
        self.amount = amount
        self.balanceAfter = balanceAfter
        self.date = date
    }
}
