import Foundation

/// Renders cooking amounts using common kitchen fractions
/// (½, ⅓, ¼, ⅛, ⅔, ¾, ⅜, ⅝, ⅞) when the value is close to one,
/// otherwise a tidy decimal.
enum FractionFormatter {

    /// Common kitchen fractions, ordered. Each maps a decimal remainder to a glyph.
    private static let fractions: [(value: Double, glyph: String)] = [
        (1.0 / 8.0, "⅛"),
        (1.0 / 4.0, "¼"),
        (1.0 / 3.0, "⅓"),
        (3.0 / 8.0, "⅜"),
        (1.0 / 2.0, "½"),
        (5.0 / 8.0, "⅝"),
        (2.0 / 3.0, "⅔"),
        (3.0 / 4.0, "¾"),
        (7.0 / 8.0, "⅞")
    ]

    /// Tolerance for snapping a remainder to a known fraction.
    private static let tolerance = 0.04

    /// Format `value` for display. When `useFractions` is false, returns a decimal.
    static func string(_ value: Double, useFractions: Bool = true) -> String {
        guard value.isFinite else { return "—" }

        let negative = value < 0
        let magnitude = abs(value)

        if !useFractions {
            return (negative ? "-" : "") + tidyDecimal(magnitude)
        }

        let whole = magnitude.rounded(.down)
        let remainder = magnitude - whole

        // Snap to the nearest known fraction within tolerance.
        var bestGlyph: String? = nil
        var bestDistance = tolerance
        var snappedToOne = false

        // Check if remainder is essentially zero.
        if remainder < tolerance {
            return (negative ? "-" : "") + decimalWhole(whole)
        }
        // Check if remainder rounds up to a whole.
        if remainder > 1.0 - tolerance {
            return (negative ? "-" : "") + decimalWhole(whole + 1)
            // snappedToOne handled implicitly
        }

        for frac in fractions {
            let d = abs(remainder - frac.value)
            if d < bestDistance {
                bestDistance = d
                bestGlyph = frac.glyph
            }
        }

        if let glyph = bestGlyph {
            _ = snappedToOne
            if whole == 0 {
                return (negative ? "-" : "") + glyph
            } else {
                return (negative ? "-" : "") + decimalWhole(whole) + glyph
            }
        }

        // No close fraction — fall back to a tidy decimal.
        return (negative ? "-" : "") + tidyDecimal(magnitude)
    }

    /// A whole number with no decimal point.
    private static func decimalWhole(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    /// Up to two decimal places, trailing zeros trimmed.
    static func tidyDecimal(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        if abs(value) >= 100 {
            return String(Int(value.rounded()))
        }
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        var s = String(format: "%.2f", rounded)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }
}
