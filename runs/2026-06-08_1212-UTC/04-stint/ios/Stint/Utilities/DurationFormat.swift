import Foundation

enum DurationFormat {
    /// "1:23:45" clock style for the live timer.
    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%d:%02d:%02d", h, m, s)
    }

    /// "1h 24m" compact style for lists and totals.
    static func compact(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h == 0 && m == 0 { return "0m" }
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }

    /// Decimal hours "1.41 h" for invoice-style reports.
    static func decimalHours(_ seconds: TimeInterval) -> String {
        String(format: "%.2f h", max(0, seconds) / 3600)
    }
}

enum Money {
    static func string(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: amount)) ?? "\(code) \(amount)"
    }
    static func compact(_ amount: Double, code: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = code
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }
}
