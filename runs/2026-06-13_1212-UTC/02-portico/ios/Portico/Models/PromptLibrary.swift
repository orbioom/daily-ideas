import Foundation

/// A named set of reflection prompts. The `key` is stored on each `Reflection`
/// so an edited entry re-loads the exact prompts it was written against.
struct PromptSet: Identifiable {
    let key: String
    let kind: Reflection.Kind
    let title: String
    /// Whether this set is gated behind Portico Pro.
    let pro: Bool
    let prompts: [String]

    var id: String { key }
}

/// Hand-written morning and evening prompt sets, drawn from the classic Stoic
/// practices of *praemeditatio* (morning preparation) and the evening review
/// described by Seneca and Epictetus.
enum PromptLibrary {
    static let morning = PromptSet(
        key: "morning.classic",
        kind: .morning,
        title: "Morning preparation",
        pro: false,
        prompts: [
            "What is in my control today, and what is not?",
            "What virtue will I practise, and how?",
            "What obstacle might I meet, and how will I meet it well?"
        ])

    static let evening = PromptSet(
        key: "evening.classic",
        kind: .evening,
        title: "Evening reflection",
        pro: false,
        prompts: [
            "What did I do well today?",
            "What did I do badly, or leave undone?",
            "Where did I let emotion rule reason?",
            "What will I do better tomorrow?"
        ])

    // MARK: Pro templates — extra structured reflections.

    static let morningPro = PromptSet(
        key: "morning.negative-visualization",
        kind: .morning,
        title: "Premeditation of adversity",
        pro: true,
        prompts: [
            "What could go wrong today that I fear?",
            "If it happened, how would a wise person bear it?",
            "What good in my life do I currently take for granted?"
        ])

    static let eveningPro = PromptSet(
        key: "evening.view-from-above",
        kind: .evening,
        title: "The view from above",
        pro: true,
        prompts: [
            "Seen from a distance, how large were today's troubles really?",
            "What duty is still unfulfilled?",
            "For what, in this day, am I grateful?",
            "What did today teach me about myself?"
        ])

    static func all(for kind: Reflection.Kind) -> [PromptSet] {
        switch kind {
        case .morning: return [morning, morningPro]
        case .evening: return [evening, eveningPro]
        }
    }

    static func set(for key: String) -> PromptSet? {
        [morning, evening, morningPro, eveningPro].first { $0.key == key }
    }

    /// The default (free) set for a kind.
    static func defaultSet(for kind: Reflection.Kind) -> PromptSet {
        kind == .morning ? morning : evening
    }
}
