import Foundation
import SwiftData

/// Drives a single study session: builds the questions, tracks the cursor, grades
/// answers (persisting progress), and produces the results summary.
@MainActor
@Observable
final class QuizViewModel {

    enum Phase { case loading, playing, finished, empty }

    private(set) var phase: Phase = .loading
    private(set) var questions: [QuizQuestion] = []
    private(set) var index = 0
    private(set) var results: [AnswerResult] = []

    /// Set after an answer is submitted, until the user advances.
    private(set) var lastResult: AnswerResult?

    private var startTime = Date()
    private var sessionMode: QuizMode?

    var current: QuizQuestion? {
        guard index >= 0, index < questions.count else { return nil }
        return questions[index]
    }

    var progressFraction: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(index) / Double(questions.count)
    }

    var answeredCount: Int { results.count }
    var correctCount: Int { results.filter { $0.correct }.count }
    var leveledUpWords: [VocabWord] { results.filter { $0.leveledUp }.map { $0.question.word } }

    var accuracy: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count)
    }

    /// Builds a session. `singleMode` forces one mode; otherwise mixes `allowedModes`.
    func start(store: ProgressStore,
               allowedModes: [QuizMode],
               singleMode: QuizMode?,
               limit: Int,
               typedFillBlank: Bool) async {
        phase = .loading
        // Yield so the loading state renders for genuinely-instant builds.
        await Task.yield()

        let modes = singleMode.map { [$0] } ?? allowedModes
        sessionMode = singleMode
        let progress = store.allProgress()
        let built = LexemeEngine.buildSession(progress: progress,
                                              allowedModes: modes,
                                              limit: limit,
                                              typedFillBlank: typedFillBlank)
        questions = built
        index = 0
        results = []
        lastResult = nil
        startTime = Date()
        phase = built.isEmpty ? .empty : .playing
    }

    /// Grades the current question and records the result. Returns whether correct.
    @discardableResult
    func submit(_ given: String, store: ProgressStore) -> Bool {
        guard let q = current else { return false }
        let correct = q.isCorrect(given)
        let levels = store.grade(wordID: q.word.id, correct: correct)
        let result = AnswerResult(question: q, given: given, correct: correct,
                                  previousLevel: levels.previous, newLevel: levels.new)
        results.append(result)
        lastResult = result
        return correct
    }

    /// Advances to the next question or finishes, recording the session on finish.
    func advance(store: ProgressStore) {
        lastResult = nil
        if index + 1 < questions.count {
            index += 1
        } else {
            finish(store: store)
        }
    }

    private func finish(store: ProgressStore) {
        let duration = Date().timeIntervalSince(startTime)
        store.recordSession(mode: sessionMode,
                            total: results.count,
                            correct: correctCount,
                            duration: duration)
        phase = .finished
    }
}
