import Foundation

enum Currency {
    static var code: String { UserDefaults.standard.string(forKey: "currencyCode") ?? Locale.current.currency?.identifier ?? "USD" }

    static func string(_ value: Double, fraction: Bool = false) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
        if !fraction { f.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2 }
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
    static func precise(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = code
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

enum Fmt {
    static func hours(_ h: Double) -> String {
        h.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(h))h" : String(format: "%.1fh", h)
    }
    static func percent(_ v: Double) -> String { String(format: "%.0f%%", v * 100) }
    static func date(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    static func monthYear(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: d)
    }
    static func relativeDay(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d"; return f.string(from: d)
    }
    static func weekdayName(_ wd: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        return symbols[(wd - 1) % 7]
    }
    static func shortWeekday(_ wd: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols[(wd - 1) % 7]
    }
}
