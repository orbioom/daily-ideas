import Foundation

/// Correctness state of a single target position.
enum CharState: Equatable {
    case untyped
    case correct
    case incorrect
}

/// The result of feeding a single keystroke to the engine.
enum TypeOutcome: Equatable {
    case correct
    case incorrect
    /// Ignored because the target text is already fully typed.
    case ignoredComplete
    /// In strict mode: a wrong key while a prior error is pending — not advanced.
    case blockedStrict
}

/// Pure typing engine. Holds the target text and per-position correctness, exposes live
/// metrics, and tracks which keys were mistyped. No force-unwrap, all indexing guarded.
struct TypingEngine {
    /// Target characters being drilled.
    private(set) var target: [Character]
    /// Per-position correctness, parallel to `target`.
    private(set) var states: [CharState]
    /// The next position to type (0...target.count).
    private(set) var index: Int = 0

    /// Total keystrokes that attempted a target character (correct + incorrect inserts).
    private(set) var totalTyped: Int = 0
    /// Count of correctly typed characters currently standing (not later corrected away).
    private(set) var correctChars: Int = 0
    /// Count of keystrokes that were wrong at the moment they were pressed.
    private(set) var errorCount: Int = 0

    /// Per-key error counts keyed by a lowercased display name (e.g. "a", "space", ",").
    private(set) var keyErrors: [String: Int] = [:]

    /// Wall-clock of the first keystroke; nil until typing begins.
    private(set) var startTime: Date?
    /// Wall-clock of the most recent keystroke (used for elapsed when not finished).
    private(set) var lastTime: Date?

    /// In strict mode, the engine refuses to advance past an uncorrected error.
    var strict: Bool

    init(target: String, strict: Bool = false) {
        let chars = Array(target)
        self.target = chars
        self.states = Array(repeating: .untyped, count: chars.count)
        self.strict = strict
    }

    /// Whether every target character has been typed.
    var isComplete: Bool { index >= target.count && !target.isEmpty }

    /// Whether the current index has a standing error (used by strict mode / UI).
    var hasPendingErrorAtCursor: Bool {
        guard index > 0, index <= states.count else { return false }
        return states[index - 1] == .incorrect
    }

    /// The next character the learner should type, or nil if complete.
    var currentChar: Character? {
        guard index >= 0, index < target.count else { return nil }
        return target[index]
    }

    /// Elapsed seconds since first keystroke (wall-clock). 0 before typing starts.
    func elapsedSeconds(now: Date = Date()) -> Double {
        guard let start = startTime else { return 0 }
        let end = lastTime.map { max($0, start) } ?? start
        // While actively typing we measure to `now`; this gives a live ticking value.
        let reference = max(end, now)
        let secs = reference.timeIntervalSince(start)
        return secs.isFinite && secs > 0 ? secs : 0
    }

    /// Gross WPM = (correctChars / 5) / minutes. Guarded against divide-by-zero.
    func wpm(now: Date = Date()) -> Double {
        let secs = elapsedSeconds(now: now)
        guard secs > 0 else { return 0 }
        let minutes = secs / 60.0
        guard minutes > 0 else { return 0 }
        let value = (Double(correctChars) / 5.0) / minutes
        return value.isFinite && value >= 0 ? value : 0
    }

    /// Net WPM = gross WPM minus (errors per minute / 5). Floored at 0.
    func netWPM(now: Date = Date()) -> Double {
        let secs = elapsedSeconds(now: now)
        guard secs > 0 else { return 0 }
        let minutes = secs / 60.0
        guard minutes > 0 else { return 0 }
        let penalty = (Double(errorCount) / 5.0) / minutes
        let net = wpm(now: now) - penalty
        return net.isFinite && net > 0 ? net : 0
    }

    /// Accuracy = correctChars / totalTyped. 1.0 before any keystroke. Guarded.
    var accuracy: Double {
        guard totalTyped > 0 else { return 1.0 }
        let value = Double(correctChars) / Double(totalTyped)
        return min(1.0, max(0.0, value))
    }

    /// Feed a typed character into the engine.
    @discardableResult
    mutating func type(_ ch: Character, now: Date = Date()) -> TypeOutcome {
        guard index < target.count else { return .ignoredComplete }

        // Strict mode: don't advance while the immediately-prior position is an error.
        if strict && hasPendingErrorAtCursor {
            return .blockedStrict
        }

        if startTime == nil { startTime = now }
        lastTime = now

        let expected = target[index]
        totalTyped += 1

        let matched = (ch == expected)
        if matched {
            states[index] = .correct
            correctChars += 1
        } else {
            states[index] = .incorrect
            errorCount += 1
            recordKeyError(expected: expected)
        }
        index += 1
        return matched ? .correct : .incorrect
    }

    /// Step back one position (guarded). Returns true if it actually moved.
    @discardableResult
    mutating func backspace(now: Date = Date()) -> Bool {
        guard index > 0 else { return false }
        index -= 1
        // Undo the standing correctness contribution at this position.
        if index < states.count {
            if states[index] == .correct {
                correctChars = max(0, correctChars - 1)
            }
            states[index] = .untyped
        }
        if startTime != nil { lastTime = now }
        return true
    }

    /// Record an error against the *target* key the learner was supposed to hit.
    private mutating func recordKeyError(expected: Character) {
        let name = TypingEngine.keyName(for: expected)
        keyErrors[name, default: 0] += 1
    }

    /// Canonical lowercased key name for heatmap aggregation.
    static func keyName(for ch: Character) -> String {
        switch ch {
        case " ": return "space"
        case "\n": return "return"
        default: return ch.lowercased()
        }
    }
}
