import SwiftUI

/// How a tracker's value is entered and displayed. The logging UI adapts to this.
/// - `severity`: a 0...max ordinal slider (max depends on the user's severity-scale pref).
/// - `yesNo`: a 0/1 toggle (taken / not taken, happened / didn't).
/// - `count`: a non-negative integer stepper (cups, doses, episodes).
/// - `numeric`: a free decimal with a unit (hours of sleep, kg, °C).
enum ScaleType: String, CaseIterable, Identifiable, Codable {
    case severity
    case yesNo
    case count
    case numeric

    var id: String { rawValue }

    var title: String {
        switch self {
        case .severity: return "Severity scale"
        case .yesNo: return "Yes / No"
        case .count: return "Count"
        case .numeric: return "Numeric value"
        }
    }

    var blurb: String {
        switch self {
        case .severity: return "Rate intensity from none to worst (slider)."
        case .yesNo: return "Did it happen today? (toggle)"
        case .count: return "How many times or how much? (stepper)"
        case .numeric: return "Enter an exact number with a unit."
        }
    }

    var symbol: String {
        switch self {
        case .severity: return "slider.horizontal.3"
        case .yesNo: return "switch.2"
        case .count: return "number"
        case .numeric: return "textformat.123"
        }
    }
}
