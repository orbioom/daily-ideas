import SwiftUI
import SwiftData

/// Drives one practice round. Pure-ish state machine; persistence applied at the end.
@MainActor
@Observable
final class GameViewModel {
    enum Phase {
        case loading
        case asking
        case feedback(correct: Bool)
        case finished
    }

    private(set) var phase: Phase = .loading
    private(set) var questions: [Question] = []
    private(set) var index = 0
    private(set) var correctCount = 0
    private(set) var lastWasCorrect = false
    private(set) var lastCorrectAnswer = 0

    /// Outcomes accumulated to persist on finish.
    private var outcomes: [(question: Question, outcome: AnswerOutcome)] = []

    private var questionStart = Date.now
    private var roundStart = Date.now

    let config: GameConfig

    init(config: GameConfig) {
        self.config = config
    }

    var current: Question? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var total: Int { questions.count }

    var progressText: String { "\(min(index + 1, total)) of \(total)" }

    var starsEarned: Int { FactEngine.stars(correct: correctCount, total: total) }

    var accuracyText: String {
        guard total > 0 else { return "0%" }
        return "\(Int((Double(correctCount) / Double(total) * 100).rounded()))%"
    }

    /// Facts that improved this round (for the "getting good at" end-screen list).
    var improvingFacts: [Question] {
        outcomes.filter { $0.outcome.correct && $0.outcome.elapsedMs <= FactEngine.fastThresholdMs }
            .map { $0.question }
    }

    // MARK: Setup

    func start(profile: Profile, answerMode: AnswerMode) {
        let states = ProfileStore.factStates(for: profile)
        var rng: RandomNumberGenerator = SystemRandomNumberGenerator()
        let round = FactEngine.makeRound(ops: config.ops,
                                         maxNumber: config.maxNumber,
                                         count: config.count,
                                         existing: states,
                                         answerMode: answerMode,
                                         rng: &rng)
        questions = round
        index = 0
        correctCount = 0
        outcomes = []
        roundStart = .now
        if questions.isEmpty {
            phase = .finished
        } else {
            questionStart = .now
            phase = .asking
        }
    }

    // MARK: Answering

    /// Submit an answer value; returns whether it was correct.
    @discardableResult
    func submit(_ value: Int) -> Bool {
        guard case .asking = phase, let q = current else { return false }
        let elapsedMs = Int(Date.now.timeIntervalSince(questionStart) * 1000)
        let correct = value == q.answer
        lastWasCorrect = correct
        lastCorrectAnswer = q.answer
        if correct { correctCount += 1 }
        let outcome = AnswerOutcome(identityKey: q.identityKey,
                                    correct: correct,
                                    elapsedMs: max(0, elapsedMs))
        outcomes.append((q, outcome))
        phase = .feedback(correct: correct)
        return correct
    }

    /// Advance to the next question (or finish).
    func advance() {
        guard case .feedback = phase else { return }
        if index + 1 < questions.count {
            index += 1
            questionStart = .now
            phase = .asking
        } else {
            phase = .finished
        }
    }

    // MARK: Persistence

    /// Persist all outcomes + the session. Safe to call once when finished.
    func persist(profile: Profile, context: ModelContext) {
        for entry in outcomes {
            ProfileStore.record(outcome: entry.outcome,
                                question: entry.question,
                                in: profile,
                                context: context)
        }
        let duration = Date.now.timeIntervalSince(roundStart)
        ProfileStore.saveSession(profile: profile,
                                 opRaw: config.modeRaw,
                                 levelIndex: config.levelIndex,
                                 total: total,
                                 correct: correctCount,
                                 durationSec: duration,
                                 stars: starsEarned,
                                 context: context)
        ProfileStore.advanceLevelIfReady(profile, context: context)
    }
}
