import Foundation

@Observable
final class BreakSessionEngine {
    var exercises: [Exercise] = []
    var currentIndex: Int = 0
    var phase: BreakPhase = .ready
    var timeRemaining: Int = 0
    var isRunning: Bool = false
    var restCountdown: Int = 3
    private var timer: Timer?

    enum BreakPhase {
        case ready, exercising, resting, complete
    }

    var currentExercise: Exercise? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var nextExercise: Exercise? {
        guard currentIndex + 1 < exercises.count else { return nil }
        return exercises[currentIndex + 1]
    }

    func startSession(exercises: [Exercise]) {
        self.exercises = exercises
        currentIndex = 0
        phase = .ready

        guard !exercises.isEmpty else {
            phase = .complete
            return
        }

        timeRemaining = exercises[0].durationSeconds
        phase = .exercising
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        if phase == .resting {
            restCountdown -= 1
            if restCountdown <= 0 {
                guard currentIndex < exercises.count else {
                    phase = .complete
                    timer?.invalidate()
                    isRunning = false
                    return
                }
                phase = .exercising
                timeRemaining = exercises[currentIndex].durationSeconds
                restCountdown = 3
            }
            return
        }

        guard timeRemaining > 0 else {
            advanceExercise()
            return
        }
        timeRemaining -= 1
    }

    private func advanceExercise() {
        currentIndex += 1
        if currentIndex >= exercises.count {
            phase = .complete
            timer?.invalidate()
            isRunning = false
        } else {
            phase = .resting
            restCountdown = 3
        }
    }

    func skip() {
        advanceExercise()
    }

    func pause() {
        timer?.invalidate()
        isRunning = false
    }

    func resume() {
        guard phase != .complete else { return }
        startTimer()
    }

    func stopSession() {
        timer?.invalidate()
        isRunning = false
        phase = .complete
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentIndex) / Double(exercises.count)
    }

    var progressFraction: Double {
        guard let ex = currentExercise, ex.durationSeconds > 0 else { return 0 }
        return Double(ex.durationSeconds - timeRemaining) / Double(ex.durationSeconds)
    }

    var totalExercises: Int { exercises.count }

    var isComplete: Bool { phase == .complete }
}
