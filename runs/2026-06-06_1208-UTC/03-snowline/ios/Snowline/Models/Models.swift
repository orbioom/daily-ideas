import SwiftUI
import SwiftData

/// Kinds of debt, for grouping and iconography.
enum DebtKind: String, Codable, CaseIterable, Identifiable {
    case creditCard, personalLoan, auto, student, medical, mortgage, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .creditCard: return "Credit card"
        case .personalLoan: return "Personal loan"
        case .auto: return "Auto loan"
        case .student: return "Student loan"
        case .medical: return "Medical"
        case .mortgage: return "Mortgage"
        case .other: return "Other"
        }
    }
    var symbol: String {
        switch self {
        case .creditCard: return "creditcard"
        case .personalLoan: return "banknote"
        case .auto: return "car"
        case .student: return "graduationcap"
        case .medical: return "cross.case"
        case .mortgage: return "house"
        case .other: return "doc.text"
        }
    }
}

/// Payoff strategy ordering.
enum Strategy: String, CaseIterable, Identifiable {
    case avalanche, snowball
    var id: String { rawValue }
    var label: String { self == .avalanche ? "Avalanche" : "Snowball" }
    var blurb: String {
        self == .avalanche
            ? "Targets the highest interest rate first — least interest paid."
            : "Targets the smallest balance first — quick wins for momentum."
    }
}

@Model
final class Debt {
    var id: UUID = UUID()
    var name: String = ""
    var kindRaw: String = DebtKind.creditCard.rawValue
    var balance: Double = 0
    var apr: Double = 0          // annual percentage rate, e.g. 19.99
    var minPayment: Double = 0
    var includeInPlan: Bool = true
    var order: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Payment.debt)
    var payments: [Payment] = []

    init(name: String, balance: Double = 0, apr: Double = 0, minPayment: Double = 0,
         kind: DebtKind = .creditCard) {
        self.name = name
        self.balance = max(0, balance)
        self.apr = max(0, apr)
        self.minPayment = max(0, minPayment)
        self.kindRaw = kind.rawValue
    }

    var kind: DebtKind {
        get { DebtKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }
    /// Monthly interest at the current balance — useful to flag stuck debts.
    var monthlyInterest: Double { balance * apr / 100.0 / 12.0 }
    var orderedPayments: [Payment] { payments.sorted { $0.date > $1.date } }
}

@Model
final class Payment {
    var id: UUID = UUID()
    var amount: Double = 0
    var date: Date = Date()
    var note: String = ""
    var debt: Debt?

    init(amount: Double, date: Date = Date(), note: String = "") {
        self.amount = max(0, amount)
        self.date = date
        self.note = note
    }
}
