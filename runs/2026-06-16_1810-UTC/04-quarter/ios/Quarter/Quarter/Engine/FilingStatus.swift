import Foundation

/// Filing statuses supported by the estimator.
enum FilingStatus: String, CaseIterable, Identifiable, Codable {
    case single
    case marriedFilingJointly
    case marriedFilingSeparately
    case headOfHousehold

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single: return "Single"
        case .marriedFilingJointly: return "Married Filing Jointly"
        case .marriedFilingSeparately: return "Married Filing Separately"
        case .headOfHousehold: return "Head of Household"
        }
    }

    var shortLabel: String {
        switch self {
        case .single: return "Single"
        case .marriedFilingJointly: return "MFJ"
        case .marriedFilingSeparately: return "MFS"
        case .headOfHousehold: return "HoH"
        }
    }

    /// Additional Medicare 0.9% threshold by status.
    var additionalMedicareThreshold: Decimal {
        switch self {
        case .single: return 200_000
        case .marriedFilingJointly: return 250_000
        case .marriedFilingSeparately: return 125_000
        case .headOfHousehold: return 200_000
        }
    }
}
