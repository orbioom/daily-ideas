import Foundation
import SwiftData

/// A deductible business expense — feeds the Ledger and the Estimate.
@Model
final class ExpenseEntry {
    @Attribute(.unique) var id: UUID
    var label: String
    var amount: Double
    var date: Date
    var category: String
    var note: String

    init(id: UUID = UUID(),
         label: String,
         amount: Double,
         date: Date = .now,
         category: String = ExpenseCategory.other.rawValue,
         note: String = "") {
        self.id = id
        self.label = label
        self.amount = amount
        self.date = date
        self.category = category
        self.note = note
    }
}

/// Common Schedule-C style expense categories.
enum ExpenseCategory: String, CaseIterable, Identifiable {
    case supplies = "Supplies"
    case software = "Software"
    case homeOffice = "Home Office"
    case travel = "Travel"
    case meals = "Meals"
    case advertising = "Advertising"
    case equipment = "Equipment"
    case professional = "Professional Fees"
    case insurance = "Insurance"
    case vehicle = "Vehicle"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .supplies: return "shippingbox"
        case .software: return "laptopcomputer"
        case .homeOffice: return "house"
        case .travel: return "airplane"
        case .meals: return "fork.knife"
        case .advertising: return "megaphone"
        case .equipment: return "wrench.and.screwdriver"
        case .professional: return "briefcase"
        case .insurance: return "shield"
        case .vehicle: return "car"
        case .other: return "tag"
        }
    }

    static func from(_ raw: String) -> ExpenseCategory {
        ExpenseCategory(rawValue: raw) ?? .other
    }
}
