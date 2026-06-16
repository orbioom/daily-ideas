import Foundation

/// A small, deterministic SplitMix64-based RNG. Used for the "question of the day"
/// (seeded by the date) so the same day yields the same question across launches,
/// and anywhere a reproducible shuffle is useful.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // Avoid a zero state.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum DailyQuestion {
    /// Deterministically pick a civics question for a given date (default today).
    static func forToday(_ date: Date = Date(), calendar: Calendar = .current) -> CivicsQuestion {
        let questions = CivicsContent.questions
        guard !questions.isEmpty else {
            // Should never happen — content is bundled — but stay total.
            return CivicsQuestion(number: 1, section: .principlesOfDemocracy,
                                  prompt: "What is the supreme law of the land?",
                                  acceptableAnswers: ["the Constitution"])
        }
        let day = calendar.ordinality(of: .day, in: .era, for: date) ?? 0
        var rng = SeededGenerator(seed: UInt64(abs(day)) &+ 1)
        let index = Int(rng.next() % UInt64(questions.count))
        // index is guaranteed in range by the modulo above.
        return questions[index]
    }
}
