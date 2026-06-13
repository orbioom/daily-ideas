import SwiftUI

/// Drives a single round of trivia: timing, scoring, streaks and reveal state.
@Observable
final class QuizSession {
    let questions: [PlayableQuestion]
    let mode: GameMode
    let category: TriviaCategory?

    var index = 0
    var score = 0
    var correctCount = 0
    var streak = 0
    var bestStreak = 0
    var selected: Int? = nil
    var revealed = false
    var secondsLeft = QuizEngine.perQuestionSeconds
    var finished = false
    let timed: Bool

    private var timer: Timer?

    init(questions: [PlayableQuestion], mode: GameMode, category: TriviaCategory?) {
        self.questions = questions
        self.mode = mode
        self.category = category
        self.timed = UserDefaults.standard.object(forKey: "timedMode") as? Bool ?? true
    }

    var current: PlayableQuestion { questions[min(index, questions.count - 1)] }
    var progress: Double { questions.isEmpty ? 0 : Double(index) / Double(questions.count) }
    var questionNumber: Int { index + 1 }

    func start() { startTimer() }

    private func startTimer() {
        timer?.invalidate()
        secondsLeft = QuizEngine.perQuestionSeconds
        guard timed else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard !revealed, !finished else { return }
        if secondsLeft > 0 { secondsLeft -= 1 }
        if secondsLeft <= 0 { reveal(selected: nil) }
    }

    func choose(_ i: Int) {
        guard !revealed else { return }
        reveal(selected: i)
    }

    private func reveal(selected i: Int?) {
        guard !revealed else { return }
        revealed = true
        selected = i
        timer?.invalidate()
        let correct = (i == current.answerIndex)
        if correct {
            correctCount += 1
            streak += 1
            bestStreak = max(bestStreak, streak)
            score += QuizEngine.points(difficulty: current.difficulty, secondsLeft: secondsLeft, streak: streak)
            Haptics.success()
        } else {
            streak = 0
            Haptics.warning()
        }
    }

    func next() {
        if index < questions.count - 1 {
            index += 1
            selected = nil
            revealed = false
            startTimer()
        } else {
            finished = true
            timer?.invalidate()
        }
    }

    func stop() { timer?.invalidate() }
    deinit { timer?.invalidate() }
}
