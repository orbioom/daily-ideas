import Foundation

/// Human-friendly quantity formatting, including common kitchen fractions.
enum Quantity {
    /// Render a quantity like 0.5 → "½", 1.25 → "1¼", 2 → "2", 0 → "".
    static func string(_ value: Double) -> String {
        guard value > 0 else { return "" }
        let whole = Int(value)
        let frac = value - Double(whole)
        let fracStr = nearestFraction(frac)
        if whole == 0 { return fracStr.isEmpty ? trimmed(value) : fracStr }
        if fracStr.isEmpty { return "\(whole)" }
        return "\(whole)\(fracStr)"
    }

    static func withUnit(_ value: Double, unit: Unit) -> String {
        let q = string(value)
        if unit == .none { return q }
        if q.isEmpty { return unit.label }
        return "\(q) \(unit.rawValue)"
    }

    private static func nearestFraction(_ frac: Double) -> String {
        guard frac > 0.05 else { return "" }
        let options: [(Double, String)] = [
            (1.0/8, "⅛"), (1.0/4, "¼"), (1.0/3, "⅓"), (1.0/2, "½"),
            (2.0/3, "⅔"), (3.0/4, "¾"), (1.0, "")
        ]
        // Find closest; if closest is 1.0 the caller rounds up via whole part.
        var best = options[0]
        var bestDiff = abs(frac - options[0].0)
        for o in options {
            let d = abs(frac - o.0)
            if d < bestDiff { best = o; bestDiff = d }
        }
        // If it's not close to a nice fraction, fall back to a decimal.
        if bestDiff > 0.06 { return trimmed(frac) }
        return best.1
    }

    private static func trimmed(_ value: Double) -> String {
        if value == value.rounded() { return "\(Int(value))" }
        return String(format: "%.2g", value)
    }
}
