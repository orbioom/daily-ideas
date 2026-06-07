import Foundation

/// Shared number/date formatting so every screen renders values consistently.
enum Fmt {

    /// A weight in pounds, e.g. "2,431 lb".
    static func lb(_ value: Double) -> String {
        "\(grouped(value, decimals: 0)) lb"
    }

    /// A bare weight number with grouping, no unit.
    static func weight(_ value: Double) -> String {
        grouped(value, decimals: 0)
    }

    /// A CG arm in inches with one decimal, e.g. "40.3 in".
    static func inches(_ value: Double) -> String {
        String(format: "%.1f in", value)
    }

    /// A bare arm number with one decimal.
    static func arm(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    /// Gallons with up to one decimal, e.g. "53" or "26.5".
    static func gal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(format: "%.0f gal", rounded)
            : String(format: "%.1f gal", rounded)
    }

    /// Feet with grouping, e.g. "5,400 ft".
    static func feet(_ value: Double) -> String {
        "\(grouped(value, decimals: 0)) ft"
    }

    /// A signed feet value, e.g. "+1,234 ft" / "−240 ft".
    static func signedFeet(_ value: Double) -> String {
        let sign = value < 0 ? "−" : "+"
        return "\(sign)\(grouped(abs(value), decimals: 0)) ft"
    }

    /// A medium date, e.g. "Jun 7, 2026".
    static func date(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// Pounds → kilograms (1 lb = 0.45359237 kg).
    static func lbToKg(_ lb: Double) -> Double { lb * 0.45359237 }

    /// Inches → centimeters.
    static func inToCm(_ inch: Double) -> Double { inch * 2.54 }

    // MARK: - Internal

    private static func grouped(_ value: Double, decimals: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
}
