import SwiftUI
import SwiftData

/// Drives a guided routine run. Wall-clock based so it survives backgrounding /
/// relaunch: a timed step stores its start `Date`, and remaining time is recomputed
/// from that start (minus accumulated pause) whenever the view ticks or reappears.
///
/// Use with `@State private var engine = PlayerEngine(...)`. Do NOT wrap in @StateObject.
@Observable
final class PlayerEngine {
    /// High-level phase of the run.
    enum Phase: Equatable {
        case running
        case finished
    }

    /// Snapshot of one step (value type so we never touch SwiftData off the main flow).
    struct Step: Identifiable, Equatable {
        let id: UUID
        let title: String
        let iconName: String
        let kind: StepKind
        let durationSec: Int
        let note: String
    }

    // MARK: Immutable run context
    let routineID: UUID
    let routineName: String
    let timeOfDay: TimeOfDay
    let steps: [Step]

    // MARK: Observable state
    private(set) var index: Int = 0
    private(set) var phase: Phase = .running
    private(set) var isPaused: Bool = false
    /// Indices the user actually completed (timed reached zero or checkbox tapped / skipped-as-done is NOT counted).
    private(set) var completedStepIDs: Set<UUID> = []
    /// Drives view refresh ~10x/sec while a timed step runs. Read-only externally.
    private(set) var tick: Int = 0

    // MARK: Wall-clock bookkeeping for the current timed step
    /// When the current timed step began counting (nil for checkbox / not started).
    private var stepStart: Date?
    /// Seconds the current step has spent paused.
    private var stepPausedAccum: TimeInterval = 0
    /// When the current pause began (nil when running).
    private var pauseStart: Date?

    /// When the whole run began (for total duration on finish).
    private let runStart: Date

    init(routine: Routine, now: Date = Date()) {
        self.routineID = routine.id
        self.routineName = routine.name
        self.timeOfDay = routine.timeOfDay
        self.steps = routine.orderedSteps.map {
            Step(id: $0.id,
                 title: $0.title,
                 iconName: $0.iconName,
                 kind: $0.kind,
                 durationSec: max(0, $0.durationSec),
                 note: $0.note)
        }
        self.runStart = now
        if let first = steps.first, first.kind == .timed {
            stepStart = now
        }
    }

    // MARK: Derived

    var totalSteps: Int { steps.count }

    var currentStep: Step? {
        guard index >= 0, index < steps.count else { return nil }
        return steps[index]
    }

    /// 1-based human position, clamped.
    var positionText: String {
        guard totalSteps > 0 else { return "0 of 0" }
        return "Step \(min(index + 1, totalSteps)) of \(totalSteps)"
    }

    var completedCount: Int { completedStepIDs.count }

    /// Progress across the whole run, 0...1 (guarded).
    var overallProgress: Double {
        guard totalSteps > 0 else { return 0 }
        let done = min(index, totalSteps)
        return Double(done) / Double(totalSteps)
    }

    /// Whether each step has been completed, for the segment bar.
    func isStepComplete(_ step: Step) -> Bool { completedStepIDs.contains(step.id) }

    // MARK: Timed-step math (wall-clock)

    /// Elapsed seconds on the current timed step, excluding paused time.
    func elapsed(now: Date = Date()) -> TimeInterval {
        guard let start = stepStart else { return 0 }
        var paused = stepPausedAccum
        if let pauseStart { paused += now.timeIntervalSince(pauseStart) }
        return max(0, now.timeIntervalSince(start) - paused)
    }

    /// Whole seconds remaining on the current timed step (0 for checkbox).
    func remaining(now: Date = Date()) -> Int {
        guard let step = currentStep, step.kind == .timed else { return 0 }
        let rem = Double(step.durationSec) - elapsed(now: now)
        return max(0, Int(rem.rounded(.up)))
    }

    /// Fraction of the current timed step elapsed, 0...1 (guarded).
    func stepProgress(now: Date = Date()) -> Double {
        guard let step = currentStep, step.kind == .timed, step.durationSec > 0 else { return 0 }
        return min(1, elapsed(now: now) / Double(step.durationSec))
    }

    // MARK: Driving the run

    /// Called by the view's timer. Recomputes from wall clock; auto-advances a finished timed step.
    /// Returns true when this tick triggered an auto-advance (so the view can cue haptics/sound).
    @discardableResult
    func advanceClock(now: Date = Date()) -> Bool {
        guard phase == .running, !isPaused else { return false }
        tick &+= 1
        guard let step = currentStep, step.kind == .timed else { return false }
        if remaining(now: now) <= 0 {
            markComplete(step)
            goNext(now: now, autoFromTimer: true)
            return true
        }
        return false
    }

    /// Checkbox tap (or "Done" on a timed step) → mark complete + advance.
    func completeCurrent(now: Date = Date()) {
        guard phase == .running, let step = currentStep else { return }
        markComplete(step)
        goNext(now: now, autoFromTimer: false)
    }

    /// Skip the current step without marking it complete.
    func skip(now: Date = Date()) {
        guard phase == .running, currentStep != nil else { return }
        goNext(now: now, autoFromTimer: false)
    }

    /// Step back to the previous step (it loses its completed mark so it can be redone).
    func back(now: Date = Date()) {
        guard phase == .running, index > 0 else { return }
        index -= 1
        if let step = currentStep {
            completedStepIDs.remove(step.id)
        }
        resetStepClock(now: now)
    }

    func togglePause(now: Date = Date()) {
        isPaused ? resume(now: now) : pause(now: now)
    }

    private func pause(now: Date = Date()) {
        guard !isPaused, phase == .running else { return }
        isPaused = true
        pauseStart = now
    }

    private func resume(now: Date = Date()) {
        guard isPaused else { return }
        if let pauseStart {
            stepPausedAccum += now.timeIntervalSince(pauseStart)
        }
        pauseStart = nil
        isPaused = false
    }

    /// Force-finish (used by the player's full-step completion or by the user finishing early).
    func finish() {
        phase = .finished
        pauseStart = nil
        isPaused = false
    }

    // MARK: Internals

    private func markComplete(_ step: Step) {
        completedStepIDs.insert(step.id)
    }

    private func goNext(now: Date, autoFromTimer: Bool) {
        if index >= steps.count - 1 {
            finish()
        } else {
            index += 1
            resetStepClock(now: now)
        }
    }

    /// Reset the wall-clock bookkeeping for whichever step is now current.
    private func resetStepClock(now: Date) {
        stepPausedAccum = 0
        pauseStart = isPaused ? now : nil
        if let step = currentStep, step.kind == .timed {
            stepStart = now
        } else {
            stepStart = nil
        }
    }

    // MARK: Persisting the run

    /// Total whole seconds the run has been going (for the completion stat / record).
    func runDuration(now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(runStart).rounded()))
    }

    /// Build the RoutineRun record for this run (completed or abandoned).
    func makeRun(routineRef: Routine?, now: Date = Date()) -> RoutineRun {
        let duration = runDuration(now: now)
        return RoutineRun(date: runStart,
                          routineName: routineName,
                          routineRef: routineRef,
                          completedSteps: completedCount,
                          totalSteps: totalSteps,
                          durationSec: duration)
    }
}
