import Foundation

/// Deterministic 64-bit RNG so the daily quiz is identical for everyone, every day.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct PlayableQuestion: Identifiable {
    let base: TriviaQuestion
    let choices: [String]
    let answerIndex: Int
    var id: Int { base.id }
    var category: TriviaCategory { base.category }
    var difficulty: Difficulty { base.difficulty }
    var prompt: String { base.prompt }
    var fact: String { base.fact }
}

enum QuizEngine {
    static let dailyCount = 10

    static func dayKey(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.timeZone = .current
        return f.string(from: date)
    }

    private static func fnv64(_ s: String) -> UInt64 {
        var hash: UInt64 = 0xCBF2_9CE4_8422_2325
        for b in s.utf8 { hash = (hash ^ UInt64(b)) &* 0x0000_0100_0000_01B3 }
        return hash
    }

    /// The fixed daily set for a date — same for every player.
    static func daily(for date: Date, bank: [TriviaQuestion] = QuestionBank.all) -> [PlayableQuestion] {
        var rng = SplitMix64(seed: fnv64(dayKey(date)))
        // Sample across difficulties for a balanced ten.
        let pool = bank.shuffled(using: &rng)
        let picked = Array(pool.prefix(dailyCount))
        var out: [PlayableQuestion] = []
        for q in picked { out.append(playable(q, rng: &rng)) }
        return out
    }

    /// A practice round (random each time).
    static func practice(category: TriviaCategory?, difficulty: Difficulty?, count: Int,
                         bank: [TriviaQuestion] = QuestionBank.all) -> [PlayableQuestion] {
        var rng = SystemRandomNumberGenerator()
        var pool = bank
        if let category { pool = pool.filter { $0.category == category } }
        if let difficulty { pool = pool.filter { $0.difficulty == difficulty } }
        if pool.count < count { // relax difficulty if too few
            pool = category.map { c in bank.filter { $0.category == c } } ?? bank
        }
        let picked = Array(pool.shuffled(using: &rng).prefix(count))
        var out: [PlayableQuestion] = []
        for q in picked {
            out.append(playable(q, rng: &rng))
        }
        return out
    }

    private static func playable<G: RandomNumberGenerator>(_ q: TriviaQuestion, rng: inout G) -> PlayableQuestion {
        let order = Array(0..<q.choices.count).shuffled(using: &rng)
        let choices = order.map { q.choices[$0] }
        let newAnswer = order.firstIndex(of: q.answerIndex) ?? 0
        return PlayableQuestion(base: q, choices: choices, answerIndex: newAnswer)
    }

    /// Points for a correct answer: difficulty base + a time bonus + a streak bonus.
    static func points(difficulty: Difficulty, secondsLeft: Int, streak: Int) -> Int {
        let base = difficulty.points
        let timeBonus = max(0, secondsLeft) * 5
        let streakBonus = min(streak, 5) * 20
        return base + timeBonus + streakBonus
    }

    static let perQuestionSeconds = 20
}
