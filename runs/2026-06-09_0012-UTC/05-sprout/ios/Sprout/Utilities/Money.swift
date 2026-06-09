import Foundation

enum Money {
    static func string(_ amount: Double, symbol: String = "$", showsSign: Bool = false) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = amount == amount.rounded() ? 0 : 2
        f.minimumFractionDigits = amount == amount.rounded() ? 0 : 2
        let number = f.string(from: NSNumber(value: abs(amount))) ?? "0"
        let sign = amount < 0 ? "−" : (showsSign ? "+" : "")
        return "\(sign)\(symbol)\(number)"
    }
}

enum Format {
    static let shortDate: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
    static let monthDay: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f
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
}
