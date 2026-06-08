import Foundation
import SwiftData

/// A single money movement. `amount` is always positive; `isIncome` gives the
/// sign. Stored as Double rounded to cents on save.
@Model
final class Transaction {
    var date: Date
    var amount: Double
    var note: String
    var categoryRaw: String
    var isIncome: Bool
    var createdAt: Date

    init(date: Date = .now,
         amount: Double,
         category: Category,
         note: String = "",
         isIncome: Bool = false) {
        self.date = date
        self.amount = max(0, (amount * 100).rounded() / 100)
        self.note = note
        self.categoryRaw = category.rawValue
        self.isIncome = isIncome
        self.createdAt = .now
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var signedAmount: Double { isIncome ? amount : -amount }
}

/// A recurring monthly budget limit for an expense category.
@Model
final class BudgetItem {
    var categoryRaw: String
    var monthlyLimit: Double

    init(category: Category, monthlyLimit: Double) {
        self.categoryRaw = category.rawValue
        self.monthlyLimit = max(0, monthlyLimit)
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

/// A recurring transaction template that auto-posts on its day each month.
@Model
final class RecurringRule {
    var title: String
    var amount: Double
    var categoryRaw: String
    var isIncome: Bool
    var dayOfMonth: Int
    var lastPosted: Date?
    var isActive: Bool

    init(title: String,
         amount: Double,
         category: Category,
         isIncome: Bool,
         dayOfMonth: Int) {
        self.title = title
        self.amount = max(0, amount)
        self.categoryRaw = category.rawValue
        self.isIncome = isIncome
        self.dayOfMonth = min(max(dayOfMonth, 1), 28)
        self.lastPosted = nil
        self.isActive = true
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}
