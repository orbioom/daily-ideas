import Foundation

extension Array {
    /// Safe subscript: returns nil rather than trapping on out-of-range access.
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension String {
    /// Strips diacritics (accents) and lowercases, for lenient answer comparison.
    /// "comió" -> "comio", "Étudié" -> "etudie".
    var foldedForComparison: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trimmed + lowercased but accents preserved, for strict comparison.
    var normalizedStrict: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: Locale(identifier: "en_US"))
    }

    /// Whether this string contains at least one accented character.
    var hasDiacritics: Bool {
        foldedForComparison != normalizedStrict
    }
}
