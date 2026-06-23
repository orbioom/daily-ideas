import Foundation

/// Formats ingredient quantities as friendly cooking fractions (1 ½, ¾, etc.).
enum Quantity {
    /// Common kitchen fractions in eighths.
    private static let glyphs: [Int: String] = [
        0: "", 1: "⅛", 2: "¼", 3: "⅜", 4: "½", 5: "⅝", 6: "¾", 7: "⅞"
    ]

    /// Returns a display string for a quantity, or nil for "to taste" (0).
    static func format(_ value: Double) -> String? {
        guard value > 0 else { return nil }
        // Round to nearest eighth to avoid floating-point noise.
        let eighths = Int((value * 8).rounded())
        guard eighths > 0 else { return nil }
        let whole = eighths / 8
        let remainder = eighths % 8

        if remainder == 0 {
            return "\(whole)"
        }
        let frac = glyphs[remainder] ?? ""
        if whole == 0 {
            return frac
        }
        return "\(whole) \(frac)"
    }

    /// Quantity + unit, e.g. "1 ½ cups". Returns nil when there is nothing to show.
    static func line(quantity: Double, unit: String) -> String? {
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)
        guard let q = format(quantity) else {
            return trimmedUnit.isEmpty ? nil : trimmedUnit
        }
        if trimmedUnit.isEmpty { return q }
        return "\(q) \(trimmedUnit)"
    }
}
