import SwiftUI

/// IRS-relevant trip purposes. Personal miles are tracked for business-use %
/// but are not deductible.
enum TripPurpose: String, CaseIterable, Identifiable, Codable {
    case business = "Business"
    case medical = "Medical"
    case charity = "Charity"
    case personal = "Personal"

    var id: String { rawValue }

    var isDeductible: Bool { self != .personal }

    var symbol: String {
        switch self {
        case .business: return "briefcase.fill"
        case .medical: return "cross.case.fill"
        case .charity: return "heart.fill"
        case .personal: return "person.fill"
        }
    }

    var tint: Color {
        switch self {
        case .business: return Theme.palette[0]
        case .medical: return Theme.palette[1]
        case .charity: return Theme.palette[6]
        case .personal: return Theme.inkSoft
        }
    }
}

/// Built-in expense categories. Custom categories (Pro) are stored as
/// `.other` with a free-text label on the Expense.
enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case fuel = "Fuel"
    case parking = "Parking"
    case tolls = "Tolls"
    case maintenance = "Maintenance"
    case insurance = "Insurance"
    case supplies = "Supplies"
    case meals = "Meals"
    case phone = "Phone"
    case other = "Other"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .fuel: return "fuelpump.fill"
        case .parking: return "parkingsign"
        case .tolls: return "road.lanes"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .insurance: return "shield.lefthalf.filled"
        case .supplies: return "shippingbox.fill"
        case .meals: return "fork.knife"
        case .phone: return "iphone"
        case .other: return "tag.fill"
        }
    }

    var tint: Color {
        Theme.palette[(ExpenseCategory.allCases.firstIndex(of: self) ?? 0) % Theme.palette.count]
    }

    /// Vehicle operating costs that count toward the "actual expense" method.
    var isVehicleOperating: Bool {
        switch self {
        case .fuel, .maintenance, .insurance, .tolls, .parking:
            return true
        case .supplies, .meals, .phone, .other:
            return false
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var colorScheme: ColorScheme? { self == .system ? nil : (self == .light ? .light : .dark) }
}
