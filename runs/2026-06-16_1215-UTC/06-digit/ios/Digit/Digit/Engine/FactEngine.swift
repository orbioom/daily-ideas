import Foundation

/// One question presented to the child.
struct Question: Identifiable {
    let id = UUID()
    let op: MathOp
    let a: Int
    let b: Int
    let answer: Int
    /// For multiple-choice mode: shuffled options including the correct answer.
    let choices: [Int]

    var prompt: String { "\(a) \(op.symbol) \(b)" }
    var identityKey: String { "\(op.rawValue)-\(a)-\(b)" }
}

/// The result of answering one question (used to update mastery).
struct AnswerOutcome {
    let identityKey: String
    let correct: Bool
    let elapsedMs: Int
}

/// Pure adaptive question generation + mastery math. No SwiftData, no UI.
enum FactEngine {

    // MARK: - Fact enumeration

    /// All valid facts for a set of ops within a max number.
    /// Division facts are generated so the result is always a whole number,
    /// and the divisor is never zero.
    static func allFacts(ops: [MathOp], maxNumber: Int) -> [(op: MathOp, a: Int, b: Int)] {
        let cap = max(1, maxNumber)
        var out: [(MathOp, Int, Int)] = []
        for op in ops {
            switch op {
            case .add:
                for a in 0...cap {
                    for b in 0...cap where a + b <= cap {
                        out.append((.add, a, b))
                    }
                }
            case .sub:
                // a - b with non-negative result, a within cap.
                for a in 0...cap {
                    for b in 0...a {
                        out.append((.sub, a, b))
                    }
                }
            case .mul:
                for a in 1...cap {
                    for b in 1...cap {
                        out.append((.mul, a, b))
                    }
                }
            case .div:
                // Build from multiplication so results are always whole and divisor > 0.
                for divisor in 1...cap {
                    for quotient in 1...cap {
                        let dividend = divisor * quotient
                        out.append((.div, dividend, divisor))
                    }
                }
            }
        }
        return out.map { (op: $0.0, a: $0.1, b: $0.2) }
    }

    static func answerValue(op: MathOp, a: Int, b: Int) -> Int {
        switch op {
        case .add: return a + b
        case .sub: return a - b
        case .mul: return a * b
        case .div: return b == 0 ? a : a / b   // guarded: divisor 0 never reached for real facts
        }
    }

    // MARK: - Adaptive selection

    /// Lightweight snapshot of a fact's learning state, decoupled from SwiftData.
    struct FactState {
        let op: MathOp
        let a: Int
        let b: Int
        let masteryLevel: Int
        let timesSeen: Int
        let lastSeen: Date?
        var identityKey: String { "\(op.rawValue)-\(a)-\(b)" }
    }

    /// Weight a candidate fact higher when it is: unseen, low-mastery, or due for review.
    /// Always returns a strictly positive weight so selection never divides by zero.
    static func weight(for state: FactState?, now: Date) -> Double {
        guard let state else { return 6.0 } // unseen-and-uninitialised: high priority
        if state.timesSeen == 0 { return 6.0 } // never practiced

        // Lower mastery → higher weight.
        let masteryComponent = Double(3 - max(0, min(3, state.masteryLevel))) + 0.5

        // Spaced repetition: facts not seen for a while are "due".
        var dueComponent = 0.0
        if let last = state.lastSeen {
            let days = now.timeIntervalSince(last) / 86_400
            // Higher mastery means a longer comfortable interval before review.
            let interval = Double(state.masteryLevel + 1) * 1.5
            dueComponent = max(0, days - interval) * 0.6
        }
        return max(0.25, masteryComponent + dueComponent)
    }

    /// Generate an adaptive round. `existing` maps identityKey → FactState.
    /// Guaranteed non-crashing for any inputs; returns [] only if no facts exist at all.
    static func makeRound(ops requestedOps: [MathOp],
                          maxNumber: Int,
                          count requestedCount: Int,
                          existing: [String: FactState],
                          answerMode: AnswerMode,
                          now: Date = .now,
                          rng: inout RandomNumberGenerator) -> [Question] {
        let ops = requestedOps.isEmpty ? [.add] : requestedOps
        let pool = allFacts(ops: ops, maxNumber: maxNumber)
        guard !pool.isEmpty else { return [] }

        let count = max(1, min(requestedCount, max(1, pool.count)))

        // Weighted sampling without replacement.
        var candidates = pool
        var chosen: [(op: MathOp, a: Int, b: Int)] = []

        while chosen.count < count && !candidates.isEmpty {
            let weights = candidates.map { fact -> Double in
                let key = "\(fact.op.rawValue)-\(fact.a)-\(fact.b)"
                return weight(for: existing[key], now: now)
            }
            let total = weights.reduce(0, +)
            guard total > 0 else {
                // Degenerate (shouldn't happen — weights are positive): pick first remaining.
                chosen.append(candidates.removeFirst())
                continue
            }
            var roll = Double.random(in: 0..<total, using: &rng)
            var pickIndex = 0
            for (i, w) in weights.enumerated() {
                roll -= w
                if roll < 0 { pickIndex = i; break }
                pickIndex = i
            }
            chosen.append(candidates.remove(at: pickIndex))
        }

        // If the pool was smaller than requested count, allow repeats to fill the round.
        while chosen.count < count {
            if let extra = pool.randomElement(using: &rng) {
                chosen.append(extra)
            } else {
                break
            }
        }

        return chosen.map { fact in
            let answer = answerValue(op: fact.op, a: fact.a, b: fact.b)
            let choices = answerMode == .multipleChoice
                ? distractors(for: fact.op, a: fact.a, b: fact.b, answer: answer, rng: &rng)
                : [answer]
            return Question(op: fact.op, a: fact.a, b: fact.b, answer: answer, choices: choices)
        }
    }

    // MARK: - Distractors (near misses), guarded

    /// Build 4 shuffled choices: the answer plus 3 plausible, distinct, non-negative distractors.
    static func distractors(for op: MathOp, a: Int, b: Int, answer: Int,
                            rng: inout RandomNumberGenerator) -> [Int] {
        var set = Set<Int>([answer])
        // Candidate near-misses ordered by plausibility.
        var candidates: [Int] = []
        candidates.append(answer + 1)
        candidates.append(answer - 1)
        candidates.append(answer + 2)
        candidates.append(answer - 2)

        switch op {
        case .add, .sub:
            candidates.append(a)
            candidates.append(b)
            candidates.append(answer + 10)
        case .mul:
            candidates.append(answer + a)   // off-by-one-row error
            candidates.append(answer - a)
            candidates.append(answer + b)
            candidates.append(a + b)        // confused × with +
        case .div:
            candidates.append(answer + 1)
            candidates.append(a)            // forgot to divide
            candidates.append(b)
        }

        // Keep only valid, distinct, non-negative distractors.
        for c in candidates where c >= 0 && !set.contains(c) {
            set.insert(c)
            if set.count >= 4 { break }
        }

        // Backfill if we still need more (e.g. small answers): scan outward.
        var delta = 3
        while set.count < 4 && delta < 50 {
            let up = answer + delta
            if up >= 0 { set.insert(up) }
            if set.count < 4 {
                let down = answer - delta
                if down >= 0 { set.insert(down) }
            }
            delta += 1
        }

        return Array(set).shuffled(using: &rng)
    }

    // MARK: - Mastery update

    /// A "fast" answer is one under this many milliseconds (scaled gently by mastery growth).
    static let fastThresholdMs = 4_000

    /// Compute the next mastery level + fastest time after an outcome.
    /// Increases on correct+fast, decreases on wrong (floored at 0), stays on correct-but-slow.
    static func updatedMastery(currentLevel: Int,
                               currentFastestMs: Int?,
                               outcome: AnswerOutcome) -> (level: Int, fastestMs: Int?) {
        let clamped = max(0, min(3, currentLevel))
        var newLevel = clamped
        if outcome.correct {
            let fastEnough = outcome.elapsedMs <= fastThresholdMs
            if fastEnough {
                newLevel = min(3, clamped + 1)
            }
            // correct-but-slow keeps the level (no regression, no jump)
        } else {
            newLevel = max(0, clamped - 1)
        }

        var fastest = currentFastestMs
        if outcome.correct {
            if let existing = fastest {
                fastest = min(existing, max(0, outcome.elapsedMs))
            } else {
                fastest = max(0, outcome.elapsedMs)
            }
        }
        return (newLevel, fastest)
    }

    /// Stars (0...3) for a finished round based on accuracy.
    static func stars(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        let acc = Double(correct) / Double(total)
        switch acc {
        case 1.0: return 3
        case 0.8..<1.0: return 2
        case 0.5..<0.8: return 1
        default: return 0
        }
    }
}
