import Foundation

/// Shared, locale-aware formatting helpers. Pure and crash-proof.
enum Format {
    /// Format a Decimal salary as a compact currency string (e.g. "$120K").
    static func salary(_ value: Decimal, currencyCode: String) -> String {
        let doubleValue = NSDecimalNumber(decimal: value).doubleValue
        let symbol = currencySymbol(currencyCode)
        if doubleValue >= 1000 {
            let thousands = doubleValue / 1000
            // Show one decimal only when it adds information.
            if thousands.rounded() == thousands {
                return "\(symbol)\(Int(thousands))K"
            }
            return "\(symbol)\(String(format: "%.1f", thousands))K"
        }
        return "\(symbol)\(Int(doubleValue.rounded()))"
    }

    /// Format a salary range. Either bound may be nil.
    static func salaryRange(min: Decimal?, max: Decimal?, currencyCode: String) -> String? {
        switch (min, max) {
        case let (lo?, hi?):
            return "\(salary(lo, currencyCode: currencyCode)) – \(salary(hi, currencyCode: currencyCode))"
        case let (lo?, nil):
            return "From \(salary(lo, currencyCode: currencyCode))"
        case let (nil, hi?):
            return "Up to \(salary(hi, currencyCode: currencyCode))"
        default:
            return nil
        }
    }

    static func currencySymbol(_ code: String) -> String {
        switch code.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "CAD": return "C$"
        case "AUD": return "A$"
        case "INR": return "₹"
        default: return code.uppercased() + " "
        }
    }

    private static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let mediumDateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func date(_ date: Date) -> String { mediumDate.string(from: date) }
    static func dateTime(_ date: Date) -> String { mediumDateTime.string(from: date) }

    /// Relative phrase like "in 3 days" / "2 days ago" / "Today".
    static func relative(_ date: Date, reference: Date = Date()) -> String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: reference), to: cal.startOfDay(for: date)).day ?? 0
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case let d where d > 1: return "in \(d) days"
        default: return "\(-days) days ago"
        }
    }

    static func percent(_ ratio: Double) -> String {
        let clamped = max(0, min(1, ratio))
        return "\(Int((clamped * 100).rounded()))%"
    }
}
