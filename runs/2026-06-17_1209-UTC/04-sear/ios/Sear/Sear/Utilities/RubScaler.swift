import Foundation

/// Scales the numeric quantity that appears after a dash in an ingredient line,
/// e.g. "Paprika — 4 tbsp" at 2× becomes "Paprika — 8 tbsp". Falls back gracefully
/// when no number is found.
enum RubScaler {

    static func scaled(_ ingredient: String, by factor: Double) -> String {
        guard factor != 1 else { return ingredient }
        // Split on the em dash used in built-in rubs; if absent, return unchanged.
        guard let dashRange = ingredient.range(of: "—") else { return ingredient }
        let name = String(ingredient[..<dashRange.upperBound])
        let amountPart = String(ingredient[dashRange.upperBound...])

        // Find the first number (integer or decimal) in the amount portion.
        guard let match = amountPart.range(of: #"\d+(\.\d+)?"#, options: .regularExpression) else {
            return ingredient
        }
        let numberString = String(amountPart[match])
        guard let value = Double(numberString) else { return ingredient }

        let scaled = value * factor
        let formatted: String
        if scaled == scaled.rounded() {
            formatted = String(Int(scaled))
        } else {
            formatted = String(format: "%.2f", scaled)
                .replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
        }

        let before = String(amountPart[..<match.lowerBound])
        let after = String(amountPart[match.upperBound...])
        return name + before + formatted + after
    }
}
