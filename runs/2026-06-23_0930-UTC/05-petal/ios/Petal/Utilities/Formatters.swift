import Foundation

/// Shared, cached formatters and small date helpers.
enum Fmt {
    static let mediumDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .none
        return f
    }()

    static let dayMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    /// Weight string with one decimal and unit, e.g. "5.4 kg".
    static func weight(_ kg: Double, unit: WeightUnit) -> String {
        let value = unit.fromKilograms(kg)
        return String(format: "%.1f %@", value, unit.label)
    }

    /// Relative-ish phrasing for a due date.
    static func duePhrase(for date: Date, reference: Date = .now) -> String {
        let cal = Calendar.current
        let startRef = cal.startOfDay(for: reference)
        let startDate = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: startRef, to: startDate).day ?? 0
        switch days {
        case ..<0:
            let n = -days
            return n == 1 ? "1 day overdue" : "\(n) days overdue"
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(days) days"
        }
    }

    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: a), to: cal.startOfDay(for: b)).day ?? 0
    }
}
