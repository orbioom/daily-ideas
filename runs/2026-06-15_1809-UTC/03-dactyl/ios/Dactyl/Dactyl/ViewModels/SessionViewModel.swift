import SwiftUI
import Combine

/// Drives a single typing session: owns the `TypingEngine`, a display timer for live stats,
/// and (for timed tests) a countdown. Pure UI state — persistence happens in the View via
/// the model context.
@MainActor
final class SessionViewModel: ObservableObject {
    @Published private(set) var engine: TypingEngine
    /// A ticking value that forces SwiftUI to re-read live WPM/time. Updated by the timer.
    @Published private(set) var tick: Date = Date()
    @Published private(set) var finished: Bool = false
    /// Last keystroke outcome — drives the strict-mode error banner & haptics.
    @Published private(set) var lastBlocked: Bool = false

    let config: SessionConfig

    private var timer: AnyCancellable?
    private var endByCountdown = false

    init(config: SessionConfig) {
        self.config = config
        self.engine = TypingEngine(target: config.text, strict: config.strict)
    }

    /// Seconds remaining for timed tests; nil when the session isn't time-limited.
    var secondsRemaining: Int? {
        guard let limit = config.timeLimit else { return nil }
        let elapsed = engine.elapsedSeconds(now: tick)
        return max(0, Int(ceil(limit - elapsed)))
    }

    var wpm: Double { engine.wpm(now: tick) }
    var accuracy: Double { engine.accuracy }
    var elapsed: Double { engine.elapsedSeconds(now: tick) }

    func start() {
        guard timer == nil else { return }
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.onTick() }
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func onTick() {
        tick = Date()
        // Timed-test completion.
        if let limit = config.timeLimit, !finished,
           engine.startTime != nil, engine.elapsedSeconds(now: tick) >= limit {
            endByCountdown = true
            finish()
        }
    }

    /// Handle an inserted character from the capture field.
    /// Returns the outcome so the View can fire haptics/sound.
    @discardableResult
    func handleInsert(_ ch: Character, hapticsEnabled: Bool, soundEnabled: Bool) -> TypeOutcome {
        guard !finished else { return .ignoredComplete }
        let outcome = engine.type(ch, now: Date())
        switch outcome {
        case .incorrect:
            Haptics.error(enabled: hapticsEnabled)
            KeySound.click(enabled: soundEnabled)
            lastBlocked = false
        case .correct:
            KeySound.click(enabled: soundEnabled)
            lastBlocked = false
        case .blockedStrict:
            Haptics.error(enabled: hapticsEnabled)
            lastBlocked = true
        case .ignoredComplete:
            break
        }

        // Completion when the whole target is typed (non-timed sessions).
        if config.timeLimit == nil, engine.isComplete, !finished {
            finish()
        }
        return outcome
    }

    func handleDelete() {
        guard !finished else { return }
        engine.backspace(now: Date())
        lastBlocked = false
    }

    func finish() {
        guard !finished else { return }
        finished = true
        stopTimer()
    }

    /// Reset to a fresh attempt of the same config.
    func reset() {
        stopTimer()
        engine = TypingEngine(target: config.text, strict: config.strict)
        tick = Date()
        finished = false
        lastBlocked = false
    }

    /// Snapshot the metrics into a TestResult payload at the moment of finishing.
    func buildResultPayload() -> SessionResultPayload {
        let now = engine.lastTime ?? Date()
        let duration = config.timeLimit ?? engine.elapsedSeconds(now: now)
        return SessionResultPayload(
            mode: config.mode,
            referenceTitle: config.title,
            wpm: (engine.wpm(now: now) * 10).rounded() / 10,
            accuracy: engine.accuracy,
            durationSeconds: max(0, duration),
            charCount: engine.correctChars + max(0, engine.totalTyped - engine.correctChars),
            errorCount: engine.errorCount,
            keyErrors: engine.keyErrors
        )
    }
}

/// Configuration describing what to type and how.
struct SessionConfig: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let text: String
    let mode: SessionMode
    let strict: Bool
    /// Optional finger-guide focus keys (for lessons).
    let focusKeys: [String]
    /// Optional lesson identity so progress can be updated on completion.
    let lessonID: String?
    /// Time limit in seconds for timed tests; nil for fixed-text drills.
    let timeLimit: Double?
}

/// A plain value snapshot used to create a `TestResult` and update progress.
struct SessionResultPayload {
    let mode: SessionMode
    let referenceTitle: String
    let wpm: Double
    let accuracy: Double
    let durationSeconds: Double
    let charCount: Int
    let errorCount: Int
    let keyErrors: [String: Int]
}
