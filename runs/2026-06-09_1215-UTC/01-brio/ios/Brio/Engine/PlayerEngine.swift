import SwiftUI
import UIKit

/// Drives a live guided workout. Timed steps derive their remaining time from a
/// stored `phaseEndDate` so the countdown survives brief backgrounding; rep
/// steps wait for an explicit advance. The view refreshes via a TimelineView and
/// calls `tick()` so the engine can auto-advance finished timed steps and fire
/// phase-change haptics.
@MainActor
@Observable
final class PlayerEngine {
    private(set) var steps: [WorkoutStep] = []
    private(set) var currentIndex = 0
    private(set) var phaseEndDate: Date?
    private(set) var isFinished = false
    private(set) var roundsCompleted = 0
    private(set) var elapsedSeconds = 0
    /// Bumped on every timer tick so the view re-renders the live countdown even
    /// when no other observed property changed.
    private(set) var now: Date = .now

    var isPaused = false

    /// Whether to fire haptic cues on phase changes (mirrors the Settings toggle).
    var hapticsOnCue = true

    private var workoutName = ""
    private var category: WorkoutCategory = .fullBody
    private var plannedSeconds = 0

    private var sessionStart: Date?
    private var pausedAt: Date?
    /// When paused, the seconds that were remaining on the current timed phase.
    private var pausedRemaining: Int?
    private var timer: Timer?

    // MARK: - Derived

    var currentStep: WorkoutStep? {
        guard currentIndex < steps.count else { return nil }
        return steps[currentIndex]
    }

    var nextStep: WorkoutStep? {
        let i = currentIndex + 1
        guard i < steps.count else { return nil }
        return steps[i]
    }

    var totalRounds: Int { steps.first?.totalRounds ?? 1 }

    /// 0…1 progress through the whole sequence.
    var progress: Double {
        guard steps.count > 1 else { return isFinished ? 1 : 0 }
        return min(1, Double(currentIndex) / Double(steps.count - 1))
    }

    /// Seconds remaining on the current timed phase (0 if not timed/paused-at-0).
    /// Reads `now` so the value re-derives on every observed tick.
    var phaseRemaining: Int {
        if isPaused, let r = pausedRemaining { return max(0, r) }
        guard let end = phaseEndDate else { return 0 }
        return max(0, Int(end.timeIntervalSince(now).rounded(.up)))
    }

    /// 0…1 progress within the current timed phase (for the ring).
    var phaseProgress: Double {
        guard let step = currentStep, step.isTimed, step.durationSec > 0 else { return 0 }
        let remaining = Double(phaseRemaining)
        return min(1, max(0, 1 - remaining / Double(step.durationSec)))
    }

    // MARK: - Lifecycle

    func start(_ workout: Workout, countInSeconds: Int) {
        steps = WorkoutEngine.steps(for: workout, countInSeconds: countInSeconds)
        workoutName = workout.name
        category = workout.category
        plannedSeconds = WorkoutEngine.estimatedSeconds(for: workout)
        currentIndex = 0
        isFinished = false
        isPaused = false
        roundsCompleted = 0
        elapsedSeconds = 0
        sessionStart = Date()
        pausedAt = nil
        pausedRemaining = nil
        armCurrentPhase(fireCue: false)
        scheduleTimer()
    }

    /// Stops the internal timer. Call from the view's `onDisappear`.
    func reset() {
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    /// Advances to the next step. Returns true if the session just finished.
    @discardableResult
    func advance() -> Bool {
        guard !isFinished else { return true }
        // Mark a completed round when leaving the last step of a round.
        if let step = currentStep {
            updateRoundsCompleted(after: step)
        }
        if currentIndex < steps.count - 1 {
            currentIndex += 1
            if currentStep?.kind == .done {
                finish(completed: true)
                return true
            }
            armCurrentPhase(fireCue: true)
            return false
        } else {
            finish(completed: true)
            return true
        }
    }

    func skip() {
        guard !isFinished else { return }
        Haptics.tap()
        advance()
    }

    func pauseToggle() {
        guard !isFinished else { return }
        if isPaused {
            // Resume: re-arm the phase end from the stored remaining time.
            isPaused = false
            if let r = pausedRemaining {
                phaseEndDate = Date().addingTimeInterval(Double(r))
            }
            if let pausedAt, let sessionStart {
                // Shift the session start so elapsed excludes the paused span.
                let pausedSpan = Date().timeIntervalSince(pausedAt)
                self.sessionStart = sessionStart.addingTimeInterval(pausedSpan)
            }
            pausedAt = nil
            pausedRemaining = nil
        } else {
            isPaused = true
            pausedAt = Date()
            pausedRemaining = currentStep?.isTimed == true ? phaseRemaining : nil
            phaseEndDate = nil
        }
    }

    func finishEarly() {
        guard !isFinished else { return }
        finish(completed: false)
    }

    /// Fired by the internal timer ~5x/second. Auto-advances a timed step whose
    /// remaining time has reached zero and refreshes elapsed seconds.
    func tick() {
        guard !isPaused, !isFinished else { return }
        now = Date()
        if let start = sessionStart {
            elapsedSeconds = max(0, Int(now.timeIntervalSince(start)))
        }
        if let step = currentStep, step.isTimed, let end = phaseEndDate,
           now >= end {
            advance()
        }
    }

    // MARK: - Building a log

    func buildSession() -> WorkoutSession {
        WorkoutSession(workoutName: workoutName.isEmpty ? "Workout" : workoutName,
                       category: category,
                       plannedSeconds: plannedSeconds,
                       actualSeconds: elapsedSeconds,
                       roundsCompleted: roundsCompleted,
                       completed: isFinished && finishedFully)
    }

    private(set) var finishedFully = false

    // MARK: - Internals

    private func armCurrentPhase(fireCue: Bool) {
        guard let step = currentStep else { phaseEndDate = nil; return }
        if step.isTimed, step.durationSec > 0 {
            phaseEndDate = Date().addingTimeInterval(Double(step.durationSec))
        } else {
            phaseEndDate = nil
        }
        if fireCue, hapticsOnCue {
            switch step.kind {
            case .exercise: Haptics.tap()
            case .restExercise, .restRound: Haptics.selection()
            case .done: Haptics.success()
            case .countIn: break
            }
        }
    }

    private func updateRoundsCompleted(after step: WorkoutStep) {
        // A round is "completed" when we move past a restRound boundary or finish
        // the final round's last working step.
        if step.kind == .restRound {
            roundsCompleted = max(roundsCompleted, step.roundIndex + 1)
        }
    }

    private func finish(completed: Bool) {
        isFinished = true
        finishedFully = completed
        if completed { roundsCompleted = totalRounds }
        phaseEndDate = nil
        isPaused = false
        timer?.invalidate()
        timer = nil
        if let start = sessionStart {
            elapsedSeconds = max(0, Int(Date().timeIntervalSince(start)))
        }
        if completed, hapticsOnCue { Haptics.success() }
    }
}
