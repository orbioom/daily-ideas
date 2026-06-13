import Foundation
import SwiftData

/// Drives the fretboard note-naming drill: it highlights a string/fret and the
/// learner picks the sounding note from four options. Adaptive within a round.
@Observable
final class FretboardViewModel {
    struct Question: Identifiable {
        let id = UUID()
        let string: Int
        let fret: Int
        let correct: String
        let options: [String]
    }

    let questionsPerRound = 12

    var tuning: Tuning
    var maxFret: Int
    var question: Question?
    var index = 0
    var correctCount = 0
    var selected: String?
    var isAnswered = false
    var isFinished = false

    private var startDate = Date()
    private var rng = SystemRandomNumberGenerator()

    init(tuningID: String, maxFret: Int) {
        self.tuning = Tuning.byID(tuningID)
        self.maxFret = max(3, min(12, maxFret))
    }

    var progress: Double {
        questionsPerRound == 0 ? 0 : Double(index) / Double(questionsPerRound)
    }

    func start() {
        index = 0
        correctCount = 0
        isFinished = false
        startDate = Date()
        nextQuestion()
    }

    private func nextQuestion() {
        selected = nil
        isAnswered = false
        let string = Int.random(in: 0..<tuning.stringCount, using: &rng)
        let fret = Int.random(in: 0...maxFret, using: &rng)
        let correctPC = tuning.pitchClass(string: string, fret: fret)
        let correct = Music.name(correctPC)

        // Three distinct distractors from other pitch classes.
        var pool = Set(0..<12)
        pool.remove(((correctPC % 12) + 12) % 12)
        var distractors: [String] = []
        while distractors.count < 3, let pick = pool.randomElement(using: &rng) {
            pool.remove(pick)
            distractors.append(Music.name(pick))
        }
        let options = ([correct] + distractors).shuffled(using: &rng)
        question = Question(string: string, fret: fret, correct: correct, options: options)
    }

    func answer(_ option: String) {
        guard !isAnswered, let q = question else { return }
        selected = option
        isAnswered = true
        if option == q.correct {
            correctCount += 1
            Haptics.success()
        } else {
            Haptics.warning()
        }
    }

    /// Advance after the learner has seen the result.
    func advance() {
        guard isAnswered else { return }
        index += 1
        if index >= questionsPerRound {
            isFinished = true
            question = nil
        } else {
            nextQuestion()
        }
    }

    /// Persist the completed round. Returns the saved score for the summary.
    @discardableResult
    func save(to context: ModelContext) -> Int {
        let duration = max(1, Int(Date().timeIntervalSince(startDate)))
        let label = "\(tuning.name) · 0–\(maxFret)"
        let session = PracticeSession(
            kind: .fretboard, durationSeconds: duration,
            primaryMetric: correctCount, secondaryMetric: questionsPerRound, label: label)
        context.insert(session)
        try? context.save()
        return correctCount
    }
}
