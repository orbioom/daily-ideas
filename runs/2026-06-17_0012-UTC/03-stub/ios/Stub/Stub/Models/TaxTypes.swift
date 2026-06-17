import Foundation

// MARK: - Filing status

/// US federal filing status. Raw values are persisted as strings in SwiftData.
enum FilingStatus: String, CaseIterable, Identifiable, Codable {
    case single
    case marriedJoint
    case marriedSeparate
    case headOfHousehold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single:           return "Single"
        case .marriedJoint:     return "Married, jointly"
        case .marriedSeparate:  return "Married, separately"
        case .headOfHousehold:  return "Head of household"
        }
    }

    var shortLabel: String {
        switch self {
        case .single:           return "Single"
        case .marriedJoint:     return "MFJ"
        case .marriedSeparate:  return "MFS"
        case .headOfHousehold:  return "HoH"
        }
    }
}

// MARK: - Pay type & frequency

/// How pay is entered: an hourly rate or a fixed annual salary.
enum PayType: String, CaseIterable, Identifiable, Codable {
    case hourly
    case salary

    var id: String { rawValue }
    var label: String { self == .hourly ? "Hourly" : "Salary" }
}

/// Pay frequency, with the number of paychecks per year.
enum PayFrequency: String, CaseIterable, Identifiable, Codable {
    case weekly
    case biweekly
    case semimonthly
    case monthly

    var id: String { rawValue }

    /// Paychecks per year. Always non-zero — used for safe division.
    var periodsPerYear: Int {
        switch self {
        case .weekly:       return 52
        case .biweekly:     return 26
        case .semimonthly:  return 24
        case .monthly:      return 12
        }
    }

    var label: String {
        switch self {
        case .weekly:       return "Weekly"
        case .biweekly:     return "Every 2 weeks"
        case .semimonthly:  return "Twice a month"
        case .monthly:      return "Monthly"
        }
    }

    var shortLabel: String {
        switch self {
        case .weekly:       return "Weekly"
        case .biweekly:     return "Biweekly"
        case .semimonthly:  return "Semimonthly"
        case .monthly:      return "Monthly"
        }
    }
}
