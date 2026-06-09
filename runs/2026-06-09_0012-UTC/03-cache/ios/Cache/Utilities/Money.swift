import Foundation

/// Currency formatting driven by a user-selected symbol. Amounts are stored as
/// plain Doubles; this only controls display.
enum Money {
    static func string(_ amount: Double, symbol: String = "$", showsSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = abs(amount) >= 1000 || amount == amount.rounded() ? 0 : 2
        formatter.minimumFractionDigits = 0
        let magnitude = abs(amount)
        let number = formatter.string(from: NSNumber(value: magnitude)) ?? "0"
        let sign = amount < 0 ? "−" : (showsSign ? "+" : "")
        return "\(sign)\(symbol)\(number)"
    }

    /// Compact form like "$1.2k" for tight spaces.
    static func compact(_ amount: Double, symbol: String = "$") -> String {
        let m = abs(amount)
        let sign = amount < 0 ? "−" : ""
        switch m {
        case 1_000_000...:
            return "\(sign)\(symbol)\(trim(m / 1_000_000))M"
        case 1_000...:
            return "\(sign)\(symbol)\(trim(m / 1_000))k"
        default:
            return string(amount, symbol: symbol)
        }
    }

    private static func trim(_ v: Double) -> String {
        let r = (v * 10).rounded() / 10
        return r == r.rounded() ? String(format: "%.0f", r) : String(format: "%.1f", r)
    }
}

enum Format {
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    static let monthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM yyyy"; return f
    }()

    static func relativeDay(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let diff = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: now)).day ?? 0
        switch diff {
        case 0: return "Today"
        case 1: return "Yesterday"
        default: return shortDate.string(from: date)
        }
    }

    /// "in 4 months", "in 2 years", "next month" from now to a future date.
    static func untilString(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if date <= now { return "now" }
        let comps = calendar.dateComponents([.year, .month, .day], from: now, to: date)
        let y = comps.year ?? 0, m = comps.month ?? 0
        if y >= 1 { return m > 0 ? "in \(y)y \(m)m" : "in \(y) year\(y == 1 ? "" : "s")" }
        if m >= 1 { return "in \(m) month\(m == 1 ? "" : "s")" }
        let d = comps.day ?? 0
        return d <= 1 ? "in a day" : "in \(d) days"
    }
}
