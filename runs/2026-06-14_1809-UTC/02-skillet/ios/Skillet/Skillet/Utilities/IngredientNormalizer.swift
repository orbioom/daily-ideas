import Foundation

/// Normalizes ingredient names so pantry items and recipe ingredients match
/// despite casing, plurals, and surrounding whitespace. Pure & deterministic.
enum IngredientNormalizer {

    /// Words that should never be treated as their own ingredient when stripping.
    private static let noise: Set<String> = [
        "fresh", "freshly", "chopped", "diced", "minced", "ground", "large",
        "small", "medium", "ripe", "boneless", "skinless", "cooked", "raw",
        "dried", "whole", "halved", "sliced", "grated", "shredded", "peeled"
    ]

    /// Lowercased, trimmed, descriptor-stripped, lightly singularized key.
    static func normalize(_ raw: String) -> String {
        var s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        // Drop anything in parentheses, e.g. "onion (red)".
        if let open = s.firstIndex(of: "("), let close = s.firstIndex(of: ")"), open < close {
            s.removeSubrange(open...close)
        }
        // Split on whitespace, drop noise descriptor words.
        let parts = s
            .components(separatedBy: CharacterSet(charactersIn: " ,/"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !noise.contains($0) }

        let cleaned = parts.joined(separator: " ")
        return singularize(cleaned.isEmpty ? s.trimmingCharacters(in: .whitespaces) : cleaned)
    }

    /// Very small, safe singularizer — only strips common English plural endings.
    private static func singularize(_ word: String) -> String {
        guard word.count > 3 else { return word }
        if word.hasSuffix("ies") {
            return String(word.dropLast(3)) + "y"
        }
        if word.hasSuffix("oes") || word.hasSuffix("hes") || word.hasSuffix("ses") {
            return String(word.dropLast(2))
        }
        if word.hasSuffix("s") && !word.hasSuffix("ss") {
            return String(word.dropLast())
        }
        return word
    }
}
