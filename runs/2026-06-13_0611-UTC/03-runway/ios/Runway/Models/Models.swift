import Foundation
import SwiftData

enum FlowKind: String, Codable, CaseIterable {
    case income, bill
    var label: String { self == .income ? "Income" : "Bill" }
}

enum Cadence: String, Codable, CaseIterable, Identifiable {
    case weekly, biweekly, semimonthly, monthly, everyNWeeks, everyNMonths
    var id: String { rawValue }
    var label: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .semimonthly: return "Twice a month"
        case .monthly: return "Monthly"
        case .everyNWeeks: return "Every N weeks"
        case .everyNMonths: return "Every N months"
        }
    }
}

@Model
final class RecurringItem {
    var name: String
    var amount: Double               // always positive; sign comes from kind
    var kindRaw: String
    var cadenceRaw: String
    var anchorDate: Date             // first occurrence / reference date
    var dayOfMonth: Int              // for monthly / semimonthly (first day)
    var secondDayOfMonth: Int        // for semimonthly (second day; 0 = month end)
    var interval: Int                // N for everyN cadences
    var category: String
    var isActive: Bool
    var createdAt: Date

    init(name: String, amount: Double, kind: FlowKind, cadence: Cadence,
         anchorDate: Date = .now, dayOfMonth: Int = 1, secondDayOfMonth: Int = 15,
         interval: Int = 3, category: String = "Other") {
        self.name = name
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.cadenceRaw = cadence.rawValue
        self.anchorDate = anchorDate
        self.dayOfMonth = dayOfMonth
        self.secondDayOfMonth = secondDayOfMonth
        self.interval = max(1, interval)
        self.category = category
        self.isActive = true
        self.createdAt = .now
    }

    var kind: FlowKind { FlowKind(rawValue: kindRaw) ?? .bill }
    var cadence: Cadence { Cadence(rawValue: cadenceRaw) ?? .monthly }

    /// Signed amount: income positive, bill negative.
    var signedAmount: Double { kind == .income ? amount : -amount }

    /// Approximate monthly equivalent for budgeting summaries.
    var monthlyEquivalent: Double {
        switch cadence {
        case .weekly: return amount * 52 / 12
        case .biweekly: return amount * 26 / 12
        case .semimonthly: return amount * 2
        case .monthly: return amount
        case .everyNWeeks: return amount * (52.0 / Double(interval)) / 12
        case .everyNMonths: return amount / Double(interval)
        }
    }
}

@Model
final class OneOffItem {
    var name: String
    var amount: Double
    var kindRaw: String
    var date: Date
    var category: String
    var createdAt: Date

    init(name: String, amount: Double, kind: FlowKind, date: Date, category: String = "Other") {
        self.name = name
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.date = date
        self.category = category
        self.createdAt = .now
    }

    var kind: FlowKind { FlowKind(rawValue: kindRaw) ?? .bill }
    var signedAmount: Double { kind == .income ? amount : -amount }
}

enum CategoryCatalog {
    static let billCategories = ["Housing", "Utilities", "Phone & Internet", "Subscriptions",
                                 "Insurance", "Loan", "Groceries", "Transport", "Childcare", "Other"]
    static let incomeCategories = ["Paycheck", "Side income", "Benefits", "Transfer", "Other"]

    static func icon(for category: String) -> String {
        switch category {
        case "Housing": return "house.fill"
        case "Utilities": return "bolt.fill"
        case "Phone & Internet": return "wifi"
        case "Subscriptions": return "repeat"
        case "Insurance": return "shield.fill"
        case "Loan": return "creditcard.fill"
        case "Groceries": return "cart.fill"
        case "Transport": return "car.fill"
        case "Childcare": return "figure.and.child.holdinghands"
        case "Paycheck": return "dollarsign.circle.fill"
        case "Side income": return "briefcase.fill"
        case "Benefits": return "hand.raised.fill"
        case "Transfer": return "arrow.left.arrow.right"
        default: return "circle.fill"
        }
    }
}
