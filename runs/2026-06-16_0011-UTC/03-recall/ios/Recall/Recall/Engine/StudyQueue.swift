import Foundation

/// Builds and reasons about the set of cards to study, honoring daily limits and suspension.
/// Pure functions over arrays of `Card` — no SwiftData fetches here.
enum StudyQueue {

    /// Cards that are due for review today (seen before, dueDate <= end of today, not suspended).
    static func dueReviewCards(in cards: [Card], now: Date = .now) -> [Card] {
        let cutoff = SRSEngine.endOfToday(now)
        return cards.filter { card in
            guard !card.isSuspended else { return false }
            guard !card.isNew else { return false }
            return card.dueDate <= cutoff
        }
        .sorted { $0.dueDate < $1.dueDate }
    }

    /// Brand-new cards not yet introduced, oldest-created first.
    static func newCards(in cards: [Card]) -> [Card] {
        cards.filter { !$0.isSuspended && $0.isNew }
             .sorted { $0.createdDate < $1.createdDate }
    }

    /// Count of cards due today (reviews only) for a badge.
    static func dueCount(in cards: [Card], now: Date = .now) -> Int {
        dueReviewCards(in: cards, now: now).count
    }

    /// Count of available new cards for a badge (uncapped).
    static func newCount(in cards: [Card]) -> Int {
        newCards(in: cards).count
    }

    /// The actual study queue for a normal (scheduled) session, capped by daily limits.
    /// Reviews come first, then up to `newLimit` fresh cards. Optionally shuffled.
    static func buildSessionQueue(cards: [Card],
                                  newLimit: Int,
                                  reviewLimit: Int,
                                  shuffle: Bool,
                                  now: Date = .now) -> [Card] {
        let reviews = Array(dueReviewCards(in: cards, now: now).prefix(max(0, reviewLimit)))
        let fresh = Array(newCards(in: cards).prefix(max(0, newLimit)))
        var queue = reviews + fresh
        if shuffle { queue.shuffle() }
        return queue
    }

    /// Cram queue: every active card, ignoring SRS / due dates entirely.
    static func buildCramQueue(cards: [Card], shuffle: Bool) -> [Card] {
        var queue = cards.filter { !$0.isSuspended }
        if shuffle {
            queue.shuffle()
        } else {
            queue.sort { $0.createdDate < $1.createdDate }
        }
        return queue
    }

    // MARK: - Multiple-choice distractors

    /// Build up to four answer options for a card: its real back plus up to three
    /// distractor backs drawn from other cards in the same pool. Guards small decks.
    static func multipleChoiceOptions(for card: Card,
                                      pool: [Card],
                                      shuffle: Bool = true) -> [String] {
        let correct = card.back
        // Distinct, non-empty backs from other cards (avoid the correct answer & dupes).
        var seen = Set<String>([normalizedKey(correct)])
        var distractors: [String] = []
        let others = pool.filter { $0.id != card.id }
        let source = shuffle ? others.shuffled() : others
        for other in source {
            let key = normalizedKey(other.back)
            let trimmed = other.back.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            distractors.append(other.back)
            if distractors.count == 3 { break }
        }

        var options = distractors + [correct]
        if shuffle { options.shuffle() }
        return options
    }

    // MARK: - Type-answer checking

    /// Normalize a string for forgiving answer comparison: trim, lowercase, fold
    /// diacritics, strip punctuation, and collapse interior whitespace.
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive],
                                  locale: .current)
        let allowed = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " {
                return Character(scalar)
            }
            return " "
        }
        let collapsed = String(allowed)
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Strict-equality key used to dedupe distractor backs.
    private static func normalizedKey(_ text: String) -> String {
        normalize(text)
    }

    /// True when a typed answer matches the card's back after normalization.
    static func answerMatches(typed: String, card: Card) -> Bool {
        let t = normalize(typed)
        guard !t.isEmpty else { return false }
        // Accept exact match, or match against any "/"-separated alternative in the back.
        let alternatives = card.back.split(separator: "/").map { normalize(String($0)) }
        if normalize(card.back) == t { return true }
        return alternatives.contains(t)
    }
}
