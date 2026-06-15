import Foundation

/// Generates and validates the content for each dismiss-mission. Pure value logic — the
/// playable UI lives in the Ring views; this just produces the puzzles and checks answers.
enum MissionEngine {

    // MARK: Math

    /// One arithmetic problem and its answer.
    struct MathProblem: Identifiable {
        let id = UUID()
        let prompt: String
        let answer: Int
    }

    /// Generate a single problem scaled by difficulty. Easy = two small terms, Medium = a
    /// mix incl. multiplication, Hard = three terms / larger operands. Never produces a
    /// negative answer (so the keypad has no minus sign) and never divides.
    static func makeMathProblem(difficulty: MissionDifficulty,
                                rng: inout SplitMix64) -> MathProblem {
        switch difficulty {
        case .easy:
            let a = rng.int(in: 2...12)
            let b = rng.int(in: 2...12)
            if rng.int(2) == 0 {
                return MathProblem(prompt: "\(a) + \(b)", answer: a + b)
            } else {
                let hi = max(a, b), lo = min(a, b)
                return MathProblem(prompt: "\(hi) − \(lo)", answer: hi - lo)
            }
        case .medium:
            switch rng.int(3) {
            case 0:
                let a = rng.int(in: 10...40), b = rng.int(in: 10...40)
                return MathProblem(prompt: "\(a) + \(b)", answer: a + b)
            case 1:
                let a = rng.int(in: 3...9), b = rng.int(in: 3...9)
                return MathProblem(prompt: "\(a) × \(b)", answer: a * b)
            default:
                let a = rng.int(in: 30...80), b = rng.int(in: 5...29)
                return MathProblem(prompt: "\(a) − \(b)", answer: a - b)
            }
        case .hard:
            switch rng.int(3) {
            case 0:
                let a = rng.int(in: 6...12), b = rng.int(in: 6...12), c = rng.int(in: 1...20)
                return MathProblem(prompt: "\(a) × \(b) + \(c)", answer: a * b + c)
            case 1:
                let a = rng.int(in: 20...60), b = rng.int(in: 20...60), c = rng.int(in: 1...19)
                return MathProblem(prompt: "\(a) + \(b) − \(c)", answer: a + b - c)
            default:
                let a = rng.int(in: 11...19), b = rng.int(in: 4...9)
                return MathProblem(prompt: "\(a) × \(b)", answer: a * b)
            }
        }
    }

    // MARK: Memory (tile sequence)

    /// Number of tiles in the grid that can light up. Always 4 (2×2) for clarity.
    static let memoryTileCount = 4

    /// A sequence of tile indices (0..<memoryTileCount) to repeat. Length scales with difficulty.
    static func makeMemorySequence(difficulty: MissionDifficulty,
                                   rng: inout SplitMix64) -> [Int] {
        let length: Int
        switch difficulty {
        case .easy:   length = 3
        case .medium: length = 4
        case .hard:   length = 5
        }
        return (0..<length).map { _ in rng.int(memoryTileCount) }
    }

    // MARK: Tap targets

    /// How many dots must be tapped to clear the mission, and the per-dot lifetime in seconds.
    static func tapTargetCount(difficulty: MissionDifficulty) -> Int {
        switch difficulty {
        case .easy:   return 8
        case .medium: return 14
        case .hard:   return 22
        }
    }

    static func tapDotLifetime(difficulty: MissionDifficulty) -> Double {
        switch difficulty {
        case .easy:   return 2.2
        case .medium: return 1.6
        case .hard:   return 1.1
        }
    }

    // MARK: Shake

    /// Number of shakes required (a "shake" is one accelerometer spike above threshold).
    static func shakeGoal(difficulty: MissionDifficulty) -> Int {
        switch difficulty {
        case .easy:   return 15
        case .medium: return 30
        case .hard:   return 50
        }
    }

    /// Acceleration magnitude (in g, gravity removed) that counts as one shake.
    static let shakeThreshold: Double = 1.6

    // MARK: Steady type

    private static let phrases: [String] = [
        "the early bird gets the worm",
        "a calm mind starts the day",
        "rise and shine the sun is up",
        "today is a brand new morning",
        "small steps make big mornings",
        "wake gently and move forward",
        "the dawn is yours to begin",
        "one deep breath then begin"
    ]

    /// A phrase to type exactly. Length is unchanged by difficulty (it's already steady-typing),
    /// but harder picks longer phrases.
    static func makeTypingPhrase(difficulty: MissionDifficulty,
                                 rng: inout SplitMix64) -> String {
        let pool: [String]
        switch difficulty {
        case .easy:   pool = phrases.filter { $0.count <= 26 }
        case .medium: pool = phrases
        case .hard:   pool = phrases.filter { $0.count >= 26 }
        }
        let safe = pool.isEmpty ? phrases : pool
        let idx = rng.int(safe.count)
        return safe[min(idx, safe.count - 1)]
    }

    /// Compare typed text to the target, ignoring case and trailing/leading whitespace.
    static func typingMatches(_ typed: String, target: String) -> Bool {
        normalize(typed) == normalize(target)
    }

    /// Live progress 0...1 of how much of the phrase has been typed correctly so far.
    static func typingProgress(_ typed: String, target: String) -> Double {
        let t = normalize(typed)
        let g = normalize(target)
        guard !g.isEmpty else { return 1 }
        var correct = 0
        for (i, ch) in t.enumerated() {
            guard i < g.count else { break }
            let gi = g.index(g.startIndex, offsetBy: i)
            if g[gi] == ch { correct += 1 } else { break }
        }
        return min(1, Double(correct) / Double(g.count))
    }

    private static func normalize(_ s: String) -> String {
        s.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Reps

    /// The effective number of repetitions for a mission, clamped to a sane range. `none`
    /// missions never repeat.
    static func effectiveReps(for type: MissionType, requested: Int) -> Int {
        guard type != .none else { return 0 }
        return min(10, max(1, requested))
    }
}
