import Foundation
import SwiftData

/// Drives the guided session player: step through each set, count reps or run a
/// hold timer, then a Timer-driven rest countdown between sets. Uses the
/// ChangesViewModel timer pattern (scheduledTimer + [weak self] + deinit invalidate).
@Observable
final class SessionPlayerViewModel {
    enum Phase { case working, resting, done }

    let plan: SessionPlan
    /// Index of the set currently being worked on.
    var setIndex = 0
    var phase: Phase = .working
    /// Result the user has dialled in for the *current* set (reps or seconds).
    var currentValue: Int
    /// Locked-in results for completed sets.
    var results: [Int] = []
    /// Seconds remaining on the rest countdown (when resting).
    var restRemaining = 0
    /// For seconds-based holds: elapsed seconds of the live hold.
    var holdElapsed = 0
    var holdRunning = false

    private var timer: Timer?

    var exercise: Exercise { plan.exercise }
    var unit: ExerciseUnit { plan.exercise.unit }

    init(plan: SessionPlan) {
        self.plan = plan
        // Seed the editable value with the target so the user adjusts, not starts from zero.
        self.currentValue = plan.sets.first?.target ?? plan.level.target
    }

    var currentSet: PlannedSet? {
        guard setIndex >= 0, setIndex < plan.sets.count else { return nil }
        return plan.sets[setIndex]
    }

    var setTarget: Int { currentSet?.target ?? plan.level.target }

    var progressText: String { "Set \(min(setIndex + 1, plan.totalSets)) of \(plan.totalSets)" }

    // MARK: Rep adjustment (reps unit)

    func bump(_ delta: Int) {
        currentValue = max(0, currentValue + delta)
        Haptics.tap()
    }

    // MARK: Hold timer (seconds unit)

    func startHold() {
        guard unit == .seconds, !holdRunning else { return }
        holdElapsed = 0
        holdRunning = true
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.holdTick()
        }
    }

    private func holdTick() {
        guard holdRunning else { return }
        holdElapsed += 1
        currentValue = holdElapsed
    }

    func stopHold() {
        guard holdRunning else { return }
        holdRunning = false
        timer?.invalidate()
        timer = nil
        currentValue = holdElapsed
        Haptics.soft()
    }

    // MARK: Set completion + rest

    /// Lock in the current set's result and advance to rest or finish.
    func completeSet() {
        if holdRunning { stopHold() }
        results.append(currentValue)
        Haptics.success()

        if let set = currentSet, set.restSeconds > 0, setIndex < plan.sets.count - 1 {
            beginRest(seconds: set.restSeconds)
        } else if setIndex < plan.sets.count - 1 {
            advanceToNextSet()
        } else {
            finish()
        }
    }

    private func beginRest(seconds: Int) {
        phase = .resting
        restRemaining = max(1, seconds)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.restTick()
        }
    }

    private func restTick() {
        guard phase == .resting else { return }
        restRemaining -= 1
        if restRemaining <= 0 {
            restRemaining = 0
            timer?.invalidate()
            timer = nil
            Haptics.success()
            advanceToNextSet()
        }
    }

    /// Skip the rest countdown and go straight to the next set.
    func skipRest() {
        timer?.invalidate()
        timer = nil
        advanceToNextSet()
    }

    private func advanceToNextSet() {
        setIndex += 1
        phase = .working
        holdElapsed = 0
        holdRunning = false
        currentValue = currentSet?.target ?? plan.level.target
    }

    func finish() {
        timer?.invalidate()
        timer = nil
        holdRunning = false
        phase = .done
        Haptics.success()
    }

    /// Persist the completed session and return the saved log.
    @discardableResult
    func save(to context: ModelContext) -> WorkoutLog {
        let log = WorkoutLog(exerciseID: exercise.id,
                             levelIndex: plan.level.index,
                             setResults: results)
        context.insert(log)
        try? context.save()
        return log
    }

    /// Whether every completed set met the level target.
    var hitTarget: Bool {
        guard !results.isEmpty else { return false }
        return results.allSatisfy { $0 >= plan.level.target }
    }

    deinit { timer?.invalidate() }
}
