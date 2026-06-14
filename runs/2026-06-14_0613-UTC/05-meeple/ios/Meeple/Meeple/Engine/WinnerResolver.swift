import Foundation

/// Resolves winners for a play given the active winner rule and the entered scores.
/// Allows ties (multiple winners). Always guards empty / equal-score edge cases.
enum WinnerResolver {

    /// Compute the set of winning indices into `scores` for the given rule.
    /// - Parameters:
    ///   - scores: one optional score per participant (nil = unscored).
    ///   - rule: the winner rule from settings.
    /// - Returns: indices that should be flagged as winners. Empty when undecidable.
    static func winningIndices(scores: [Int?], rule: WinnerRule) -> Set<Int> {
        switch rule {
        case .manual:
            return []
        case .highestScore, .lowestScore:
            // Only consider participants that actually have a score.
            let scored = scores.enumerated().compactMap { (idx, value) -> (Int, Int)? in
                guard let value else { return nil }
                return (idx, value)
            }
            guard !scored.isEmpty else { return [] }

            let target: Int
            switch rule {
            case .highestScore:
                target = scored.map(\.1).max() ?? 0
            case .lowestScore:
                target = scored.map(\.1).min() ?? 0
            case .manual:
                return []
            }
            return Set(scored.filter { $0.1 == target }.map(\.0))
        }
    }
}
