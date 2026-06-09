import Foundation

/// Weight units. Kilograms are canonical in storage.
enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var label: String { self == .kg ? "kg" : "lb" }

    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg * 2.2046226218 }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value / 2.2046226218 }
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
        case -1: return "Tomorrow"
        default: return shortDate.string(from: date)
        }
    }

    /// Display a kilogram value in the user's preferred unit.
    static func weight(_ kg: Double, unit: WeightUnit) -> String {
        let v = unit.fromKg(kg)
        let rounded = (v * 100).rounded() / 100
        let str = rounded == rounded.rounded() ? String(format: "%.0f", rounded) : String(format: "%.2f", rounded)
        return "\(str) \(unit.label)"
    }
}
