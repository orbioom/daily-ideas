import Foundation
import SwiftData

@Model
final class Expense {
    var date: Date
    var categoryRaw: String
    /// Free-text label used for custom categories (Pro); empty otherwise.
    var customLabel: String
    var amount: Decimal
    var deductible: Bool
    var notes: String
    var createdAt: Date

    var vehicle: Vehicle?

    init(date: Date = .now,
         category: ExpenseCategory = .fuel,
         customLabel: String = "",
         amount: Decimal = 0,
         deductible: Bool = true,
         notes: String = "",
         vehicle: Vehicle? = nil,
         createdAt: Date = .now) {
        self.date = date
        self.categoryRaw = category.rawValue
        self.customLabel = customLabel
        self.amount = amount
        self.deductible = deductible
        self.notes = notes
        self.vehicle = vehicle
        self.createdAt = createdAt
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// Display name: custom label when present, else the category's name.
    var displayCategory: String {
        let trimmed = customLabel.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? category.rawValue : trimmed
    }
}
