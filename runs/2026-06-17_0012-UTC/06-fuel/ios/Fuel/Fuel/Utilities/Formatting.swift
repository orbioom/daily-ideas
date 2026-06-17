import Foundation

/// Centralized number / date formatting helpers used across the UI.
enum Fmt {

    /// Whole calories with a thousands separator (e.g. "2,150").
    static func kcal(_ value: Double) -> String {
        let n = NSNumber(value: value.rounded())
        return (intFormatter.string(from: n) ?? "\(Int(value.rounded()))")
    }

    /// Grams, no decimals (e.g. "168 g").
    static func grams(_ value: Double) -> String {
        "\(Int(value.rounded())) g"
    }

    /// A weight in the user's display unit, 1 decimal (e.g. "80.6 kg").
    static func weight(_ kg: Double, unit: WeightUnit) -> String {
        let v = unit.fromKg(kg)
        return String(format: "%.1f %@", v, unit.label)
    }

    /// A weight value only (no unit), 1 decimal.
    static func weightValue(_ kg: Double, unit: WeightUnit) -> String {
        String(format: "%.1f", unit.fromKg(kg))
    }

    /// A signed weekly change in the user's unit (e.g. "−0.4 kg/wk", "+0.2 lb/wk").
    static func weeklyChange(_ kg: Double, unit: WeightUnit) -> String {
        let v = unit.fromKg(kg)
        if abs(v) < 0.005 { return "steady" }
        let sign = v < 0 ? "−" : "+"
        return String(format: "%@%.2f %@/wk", sign, abs(v), unit.label)
    }

    /// A percentage with one decimal (e.g. "0.6%").
    static func percent(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))%" }
        return String(format: "%.1f%%", value)
    }

    /// Whole percentage (e.g. "40%").
    static func percentWhole(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// Medium date (e.g. "Jun 17, 2026").
    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Short date (e.g. "Jun 17").
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// Relative phrasing for an upcoming due date.
    static func relativeDue(_ date: Date, from now: Date = Date()) -> String {
        let days = Int((date.timeIntervalSince(now) / 86_400).rounded())
        if days < 0 { return "\(abs(days)) day\(abs(days) == 1 ? "" : "s") overdue" }
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days) days"
    }

    private static let intFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f
    }()
}
