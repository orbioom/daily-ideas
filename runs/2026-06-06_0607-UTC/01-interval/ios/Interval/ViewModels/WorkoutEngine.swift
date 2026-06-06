import SwiftUI
import Observation
import Combine

/// Drives a single run of a flattened timeline. The scheduler is **absolute-time** based:
/// each step is given a wall-clock end `Date`, and progress is derived from `Date.now`
/// rather than accumulating ticks — so the countdown stays accurate even if the display
/// link stutters or the app is briefly backgrounded. UI updates happen on the main actor.
@MainActor
@Observable
final class WorkoutEngine {

    enum Phase: Equatable {
        /// Optional lead-in before the first step.
        case countIn
        case running
        case paused
        case completed
        /// A run that cannot start (no steps) — guarded.
        case empty
    }

    // MARK: - Public observable state

    private(set) var phase: Phase
    private(set) var steps: [TimelineStep]
    private(set) var stepIndex: Int = 0
    /// Whole seconds remaining in the current step (or count-in), clamped >= 0.
    private(set) var remainingInStep: Int = 0
    /// Continuous 0...1 progress through the current step (for the ring).
    private(set) var stepProgress: Double = 0
    /// Whole seconds remaining across the entire run (excludes count-in).
    private(set) var remainingTotal: Int = 0
    /// Count-in seconds remaining (only meaningful in `.countIn`).
    private(set) var countInRemaining: Int = 0

    let routineName: String
    let countInLength: Int

    // MARK: - Private timing

    /// Absolute time the current interval (step or count-in) is scheduled to end.
    private var intervalEnd: Date = .now
    /// Length in seconds of the current interval.
    private var intervalLength: Int = 1
    private var timerCancellable: AnyCancellable?
    private let startedAt: Date

    /// Active (un-paused) seconds accumulated, for the session record.
    private var accumulatedActive: TimeInterval = 0
    /// When the current active span began (nil while paused/stopped).
    private var activeSpanStart: Date?
    /// Last integer second we fired a tick cue for (avoids duplicate cues).
    private var lastCueSecond: Int = -1

    private let onSegmentChange: () -> Void
    private let onCountInTick: (Int) -> Void
    private let onComplete: () -> Void

    // MARK: - Init

    /// - Parameters:
    ///   - steps: the pre-flattened timeline. May be empty (→ `.empty`, guarded).
    ///   - countIn: lead-in seconds (0 disables the count-in phase).
    init(routineName: String,
         steps: [TimelineStep],
         countIn: Int,
         onSegmentChange: @escaping () -> Void = {},
         onCountInTick: @escaping (Int) -> Void = { _ in },
         onComplete: @escaping () -> Void = {}) {
        self.routineName = routineName
        self.steps = steps
        self.countInLength = max(0, countIn)
        self.startedAt = .now
        self.onSegmentChange = onSegmentChange
        self.onCountInTick = onCountInTick
        self.onComplete = onComplete

        self.remainingTotal = steps.reduce(0) { $0 + $1.duration }

        if steps.isEmpty {
            self.phase = .empty
        } else if countInLength > 0 {
            self.phase = .countIn
        } else {
            self.phase = .running
        }
    }

    // MARK: - Derived display helpers

    var currentStep: TimelineStep? {
        guard steps.indices.contains(stepIndex) else { return nil }
        return steps[stepIndex]
    }

    var nextStep: TimelineStep? {
        let next = stepIndex + 1
        guard steps.indices.contains(next) else { return nil }
        return steps[next]
    }

    var isFinalStep: Bool { stepIndex >= steps.count - 1 }

    /// Steps completed so far (current step counts as completed once passed).
    var completedSteps: Int { min(stepIndex, steps.count) }

    /// Active (un-paused) seconds so far, for the completion summary display.
    var elapsedActiveForDisplay: Int { currentActiveSeconds() }

    /// Overall 0...1 progress across the whole run by elapsed time.
    var overallProgress: Double {
        let total = steps.reduce(0) { $0 + $1.duration }
        guard total > 0 else { return 0 }
        let done = total - remainingTotal
        return min(1, max(0, Double(done) / Double(total)))
    }

    // MARK: - Lifecycle

    /// Begin the run (or count-in). Idempotent; safe to call once after construction.
    func start(haptics: Bool, sound: Bool) {
        switch phase {
        case .empty, .completed:
            return
        case .countIn:
            beginInterval(seconds: countInLength)
            countInRemaining = countInLength
        case .running, .paused:
            phase = .running
            beginInterval(seconds: steps.isEmpty ? 1 : steps[0].duration)
            remainingInStep = currentStep?.duration ?? 0
            onSegmentChange()
        }
        startActiveSpan()
        startTimer(haptics: haptics, sound: sound)
    }

    func pause() {
        guard phase == .running || phase == .countIn else { return }
        closeActiveSpan()
        // Capture remaining so resume re-schedules from a fresh "now".
        let now = Date.now
        let remaining = max(0, Int(intervalEnd.timeIntervalSince(now).rounded(.up)))
        pausedRemaining = remaining
        phase = .paused
        stopTimer()
    }

    private var pausedRemaining: Int = 0

    func resume(haptics: Bool, sound: Bool) {
        guard phase == .paused else { return }
        phase = wasInCountIn ? .countIn : .running
        beginInterval(seconds: max(1, pausedRemaining))
        startActiveSpan()
        startTimer(haptics: haptics, sound: sound)
    }

    /// True when the pause happened during the count-in.
    private var wasInCountIn = false

    /// Skip the rest of the current step immediately.
    func skip(haptics: Bool, sound: Bool) {
        guard phase == .running else { return }
        advanceStep(haptics: haptics, sound: sound)
    }

    /// Add 15 seconds to the current step's remaining time.
    func addFifteen() {
        guard phase == .running || phase == .countIn else { return }
        intervalEnd = intervalEnd.addingTimeInterval(15)
        intervalLength += 15
        if phase == .running { remainingTotal += 15 }
        refreshDisplay()
    }

    /// Stop the run early. Returns a `Session` snapshot describing what happened.
    func stop() -> SessionSnapshot {
        closeActiveSpan()
        stopTimer()
        let wasCompleted = (phase == .completed)
        phase = .completed
        return snapshot(finishedFully: wasCompleted)
    }

    // MARK: - Timer

    private func startTimer(haptics: Bool, sound: Bool) {
        stopTimer()
        lastCueSecond = -1
        // 20 Hz UI cadence for a smooth ring; correctness comes from absolute Dates.
        timerCancellable = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick(haptics: haptics, sound: sound)
            }
        refreshDisplay()
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func tick(haptics: Bool, sound: Bool) {
        guard phase == .running || phase == .countIn else { return }
        let now = Date.now
        let remaining = intervalEnd.timeIntervalSince(now)

        if remaining <= 0 {
            intervalCompleted(haptics: haptics, sound: sound)
            return
        }

        refreshDisplay()

        // Count-in / lead-in cues on each whole second of the last 3s.
        let wholeRemaining = Int(remaining.rounded(.up))
        if wholeRemaining != lastCueSecond {
            lastCueSecond = wholeRemaining
            if phase == .countIn {
                countInRemaining = wholeRemaining
                onCountInTick(wholeRemaining)
                Cue.tick(enabled: sound)
                Haptics.tick(enabled: haptics)
            } else if wholeRemaining <= 3 {
                // Final lead-in of a work/rest step.
                Cue.tick(enabled: sound)
                Haptics.tick(enabled: haptics)
            }
        }
    }

    private func intervalCompleted(haptics: Bool, sound: Bool) {
        if phase == .countIn {
            // Count-in finished → enter the first running step.
            phase = .running
            stepIndex = 0
            beginInterval(seconds: steps.first?.duration ?? 1)
            remainingInStep = currentStep?.duration ?? 0
            onSegmentChange()
            Cue.transition(enabled: sound)
            Haptics.transition(enabled: haptics)
            refreshDisplay()
            return
        }
        advanceStep(haptics: haptics, sound: sound)
    }

    /// Move to the next step, or complete the run.
    private func advanceStep(haptics: Bool, sound: Bool) {
        // Account for the time of the step we just left in remainingTotal.
        if let step = currentStep {
            remainingTotal = max(0, remainingTotal - step.duration)
        }

        if isFinalStep {
            completeRun(haptics: haptics, sound: sound)
            return
        }

        stepIndex += 1
        beginInterval(seconds: currentStep?.duration ?? 1)
        remainingInStep = currentStep?.duration ?? 0
        onSegmentChange()
        Cue.transition(enabled: sound)
        Haptics.transition(enabled: haptics)
        refreshDisplay()
    }

    private func completeRun(haptics: Bool, sound: Bool) {
        // Ensure the last step counts as completed.
        stepIndex = max(steps.count, stepIndex)
        remainingTotal = 0
        remainingInStep = 0
        stepProgress = 1
        closeActiveSpan()
        stopTimer()
        phase = .completed
        Cue.complete(enabled: sound)
        Haptics.success(enabled: haptics)
        onComplete()
    }

    // MARK: - Interval bookkeeping

    private func beginInterval(seconds: Int) {
        let length = max(1, seconds)
        intervalLength = length
        intervalEnd = Date.now.addingTimeInterval(TimeInterval(length))
        wasInCountIn = (phase == .countIn)
    }

    private func refreshDisplay() {
        let now = Date.now
        let remaining = max(0, intervalEnd.timeIntervalSince(now))
        let whole = Int(remaining.rounded(.up))
        let elapsed = Double(intervalLength) - remaining

        if phase == .countIn {
            countInRemaining = whole
            stepProgress = intervalLength > 0 ? min(1, max(0, elapsed / Double(intervalLength))) : 0
        } else {
            remainingInStep = whole
            stepProgress = intervalLength > 0 ? min(1, max(0, elapsed / Double(intervalLength))) : 0
        }
    }

    // MARK: - Active-time accounting

    private func startActiveSpan() {
        if activeSpanStart == nil { activeSpanStart = .now }
    }

    private func closeActiveSpan() {
        if let start = activeSpanStart {
            accumulatedActive += Date.now.timeIntervalSince(start)
            activeSpanStart = nil
        }
    }

    private func currentActiveSeconds() -> Int {
        var total = accumulatedActive
        if let start = activeSpanStart {
            total += Date.now.timeIntervalSince(start)
        }
        return Int(total.rounded())
    }

    /// Work seconds among the steps fully or partially completed.
    private func workSecondsDone() -> Int {
        let doneCount = min(stepIndex, steps.count)
        guard doneCount > 0 else { return 0 }
        return steps.prefix(doneCount)
            .filter { $0.kind == .work }
            .reduce(0) { $0 + $1.duration }
    }

    private func snapshot(finishedFully: Bool) -> SessionSnapshot {
        SessionSnapshot(
            startedAt: startedAt,
            endedAt: .now,
            activeSeconds: currentActiveSeconds(),
            workSeconds: workSecondsDone(),
            completedSteps: min(stepIndex, steps.count),
            totalSteps: steps.count,
            finishedFully: finishedFully,
            routineName: routineName
        )
    }
}

/// A plain value describing a finished (or stopped) run; converted into a `Session`
/// model by the view that owns the `modelContext`.
struct SessionSnapshot {
    let startedAt: Date
    let endedAt: Date
    let activeSeconds: Int
    let workSeconds: Int
    let completedSteps: Int
    let totalSteps: Int
    let finishedFully: Bool
    let routineName: String
}
