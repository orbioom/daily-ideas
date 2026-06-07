import Foundation

/// Small, allocation-light formatting helpers used across screens.
enum Format {
    static func int(_ v: Double) -> String {
        String(Int(v.rounded()))
    }

    static func signedInt(_ v: Double) -> String {
        let n = Int(v.rounded())
        return n > 0 ? "+\(n)" : "\(n)"
    }

    static func oneDecimal(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    static func twoDecimals(_ v: Double) -> String {
        String(format: "%.2f", v)
    }

    /// Minutes → "1h 20m" / "45m".
    static func duration(_ minutes: Int) -> String {
        let m = max(0, minutes)
        if m >= 60 {
            let h = m / 60
            let rem = m % 60
            return rem == 0 ? "\(h)h" : "\(h)h \(rem)m"
        }
        return "\(m)m"
    }

    static func km(_ v: Double) -> String {
        v <= 0 ? "—" : String(format: "%.1f km", v)
    }

    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    static func relativeWeek(_ date: Date, calendar: Calendar = .current) -> String {
        let now = Date()
        let weeks = (calendar.dateComponents([.weekOfYear], from: date, to: now).weekOfYear) ?? 0
        switch weeks {
        case 0: return "This week"
        case 1: return "Last week"
        default:
            let f = DateFormatter()
            f.dateFormat = "'Week of' d MMM"
            return f.string(from: date)
        }
    }
}
