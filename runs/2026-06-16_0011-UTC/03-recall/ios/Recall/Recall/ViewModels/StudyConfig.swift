import Foundation

/// Describes a study session to launch: which cards, in which mode, with which deck pool for MCQ.
struct StudyConfig: Identifiable {
    let id = UUID()
    let title: String
    let mode: ReviewMode
    /// The cards to study, in order.
    let queue: [Card]
    /// The pool used to generate multiple-choice distractors (usually the source deck's cards).
    let distractorPool: [Card]
    /// nil when studying across all decks; a log is still attached to each card's own deck.
    let scopedDeck: Deck?
}
