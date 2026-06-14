import SwiftUI
import SwiftData

/// Drives a single quiz run: holds the questions, current index, selection state,
/// scoring, optional timer, and writes results to the store on completion.
@MainActor
@Observable
final class QuizViewModel {

    enum Phase: Equatable {
        case loading
        case empty(String)      // message when no questions could be built
        case playing
        case finished
    }

    // Configuration captured at start.
    let mode: QuizMode
    let continent: Continent?
    let isDaily: Bool
    let timerEnabled: Bool

    private(set) var phase: Phase = .loading
    private(set) var questions: [QuizQuestion] = []
    private(set) var index: Int = 0
    private(set) var correctCount: Int = 0
    /// iso2 codes the learner missed (for the results "review" list).
    private(set) var missed: [String] = []
    /// The choice index the learner tapped for the current question, if any.
    private(set) var selectedChoice: Int? = nil
    private(set) var answered: Bool = false

    // Timer
    private(set) var elapsed: Double = 0
    private var startDate: Date = Date()
    private var timer: Timer?

    private let store: ProgressStore

    init(mode: QuizMode,
         continent: Continent?,
         isDaily: Bool,
         timerEnabled: Bool,
         length: Int,
         store: ProgressStore) {
        self.mode = mode
        self.continent = continent
        self.isDaily = isDaily
        self.timerEnabled = timerEnabled
        self.store = store
        build(length: length)
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: Derived

    var current: QuizQuestion? {
        guard questions.indices.contains(index) else { return nil }
        return questions[index]
    }

    var total: Int { questions.count }
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(index) / Double(total)
    }
    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }

    var missedCountries: [Country] {
        missed.compactMap { CountryData.country(for: $0) }
    }

    // MARK: Build

    private func build(length: Int) {
        phase = .loading
        if isDaily {
            questions = QuizEngine.dailyChallenge()
        } else {
            var rng = SystemRandomNumberGenerator()
            let snapshot = store.masterySnapshot()
            questions = QuizEngine.makeQuiz(mode: mode,
                                            count: length,
                                            continent: continent,
                                            snapshot: snapshot,
                                            using: &rng)
        }
        if questions.isEmpty {
            phase = .empty("There aren't enough countries to build this quiz. Try a different continent.")
        } else {
            phase = .playing
            startDate = Date()
            startTimerIfNeeded()
        }
    }

    private func startTimerIfNeeded() {
        guard timerEnabled else { return }
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.phase == .playing else { return }
                self.elapsed = Date().timeIntervalSince(self.startDate)
            }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    // MARK: Interaction

    /// Tap a choice. Grades immediately, updates progress, and reveals feedback.
    func select(_ choiceIndex: Int) {
        guard phase == .playing, !answered, let q = current else { return }
        guard q.choices.indices.contains(choiceIndex) else { return }
        selectedChoice = choiceIndex
        answered = true
        let isCorrect = choiceIndex == q.answerIndex
        if isCorrect {
            correctCount += 1
            Haptics.success()
        } else {
            missed.append(q.subjectISO2)
            Haptics.error()
        }
        // Credit the subject country in progress (skip for the shared daily? we
        // still credit — practice is practice).
        store.recordAnswer(iso2: q.subjectISO2, correct: isCorrect)
    }

    var isCurrentCorrect: Bool {
        guard let sel = selectedChoice, let q = current else { return false }
        return sel == q.answerIndex
    }

    /// Advance to the next question, or finish.
    func advance() {
        guard answered else { return }
        if index + 1 >= total {
            finish()
        } else {
            index += 1
            selectedChoice = nil
            answered = false
        }
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        if timerEnabled { elapsed = Date().timeIntervalSince(startDate) }
        phase = .finished
        Haptics.celebrate()
        let session = QuizSession(modeRaw: mode.rawValue,
                                  total: total,
                                  correct: correctCount,
                                  durationSec: elapsed,
                                  continentRaw: continent?.rawValue,
                                  isDaily: isDaily)
        store.saveSession(session)
    }

    /// The reinforcing fact for the question just answered.
    func feedbackFact() -> String? {
        guard let q = current, let subject = CountryData.country(for: q.subjectISO2) else { return nil }
        return q.reinforcement(subject: subject)
    }
}
