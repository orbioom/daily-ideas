import Foundation

/// How often a holding pays dividends. Raw-value enum so SwiftData can store it.
enum DividendFrequency: String, Codable, CaseIterable, Identifiable {
    case monthly
    case quarterly
    case semiannual
    case annual

    var id: String { rawValue }

    var label: String {
        switch self {
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .semiannual: return "Semiannual"
        case .annual: return "Annual"
        }
    }

    /// Number of payments per year.
    var paymentsPerYear: Int {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .semiannual: return 2
        case .annual: return 1
        }
    }

    /// Step in months between consecutive payments.
    var monthStep: Int {
        switch self {
        case .monthly: return 1
        case .quarterly: return 3
        case .semiannual: return 6
        case .annual: return 12
        }
    }
}

/// For quarterly/semiannual payers, which calendar cycle they land on.
/// Quarterly examples: Jan-Apr-Jul-Oct (cycle1), Feb-May-Aug-Nov (cycle2), Mar-Jun-Sep-Dec (cycle3).
enum PayCycle: String, Codable, CaseIterable, Identifiable {
    case cycle1
    case cycle2
    case cycle3

    var id: String { rawValue }

    /// 1-based first pay month for this cycle (used as the anchor month).
    var anchorMonth: Int {
        switch self {
        case .cycle1: return 1
        case .cycle2: return 2
        case .cycle3: return 3
        }
    }

    func label(for frequency: DividendFrequency) -> String {
        switch frequency {
        case .quarterly:
            switch self {
            case .cycle1: return "Jan · Apr · Jul · Oct"
            case .cycle2: return "Feb · May · Aug · Nov"
            case .cycle3: return "Mar · Jun · Sep · Dec"
            }
        case .semiannual:
            switch self {
            case .cycle1: return "Jan · Jul"
            case .cycle2: return "Feb · Aug"
            case .cycle3: return "Mar · Sep"
            }
        case .annual:
            return "Once a year"
        case .monthly:
            return "Every month"
        }
    }
}
