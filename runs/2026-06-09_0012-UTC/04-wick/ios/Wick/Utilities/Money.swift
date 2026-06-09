import Foundation

enum Money {
    static func string(_ amount: Double, symbol: String = "$", showsSign: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = abs(amount) >= 1000 ? 0 : 2
        f.minimumFractionDigits = abs(amount) >= 1000 ? 0 : (amount == amount.rounded() ? 0 : 2)
        let number = f.string(from: NSNumber(value: abs(amount))) ?? "0"
        let sign = amount < 0 ? "−" : (showsSign ? "+" : "")
        return "\(sign)\(symbol)\(number)"
    }

    static func compact(_ amount: Double, symbol: String = "$") -> String {
        let m = abs(amount), sign = amount < 0 ? "−" : (amount > 0 ? "+" : "")
        switch m {
        case 1_000_000...: return "\(sign)\(symbol)\(trim(m / 1_000_000))M"
        case 1_000...: return "\(sign)\(symbol)\(trim(m / 1_000))k"
        default: return "\(sign)\(symbol)\(trim(m))"
        }
    }

    static func price(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = value < 10 ? 4 : 2
        f.minimumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "0"
    }

    static func percent(_ value: Double) -> String {
        let sign = value > 0 ? "+" : (value < 0 ? "−" : "")
        return "\(sign)\(String(format: "%.1f", abs(value) * 100))%"
    }

    static func rMultiple(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : "−"
        return "\(sign)\(String(format: "%.2f", abs(value)))R"
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
    static let dateTime: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .short; return f
    }()
    static let monthYear: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()

    static func duration(_ interval: TimeInterval) -> String {
        let mins = Int(interval / 60)
        if mins < 60 { return "\(mins)m" }
        let hours = mins / 60
        if hours < 24 { return "\(hours)h \(mins % 60)m" }
        let days = hours / 24
        return "\(days)d \(hours % 24)h"
    }

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
}
