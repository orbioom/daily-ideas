import Foundation

enum WeightUnit: String, CaseIterable, Identifiable {
    case kg, lb

    var id: String { rawValue }
    var label: String { self == .kg ? "Kilograms (kg)" : "Pounds (lb)" }
    var suffix: String { rawValue }

    /// Smallest sensible plate jump in this unit.
    var step: Double { self == .kg ? 2.5 : 5 }

    func display(fromKg kg: Double) -> Double {
        self == .kg ? kg : kg * 2.2046226218
    }

    func toKg(_ value: Double) -> Double {
        self == .kg ? value : value / 2.2046226218
    }

    func format(kg: Double) -> String {
        "\(Weight.trim(display(fromKg: kg))) \(suffix)"
    }
}

enum Weight {
    /// "62.5" not "62.50000", "60" not "60.0".
    static func trim(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded.rounded()))
        }
        return String(format: "%.1f", rounded)
    }
}

enum Duration {
    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    static func friendly(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        if m < 60 { return "\(m) min" }
        return "\(m / 60) h \(m % 60) min"
    }
}
