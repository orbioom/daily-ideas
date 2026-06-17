import SwiftUI
import Observation

/// The wall-clock, relaunch-safe guided-session player.
///
/// Time is derived from a stored start `Date` plus a paused-accumulator rather
/// than counted by a ticking timer, so the elapsed value is correct after
/// backgrounding or a full relaunch. A `TimelineView` in the UI re-reads the
/// derived state ~4×/second; this engine only stores anchors and fires cues.
@Observable
final class PlayerEngine {

    // MARK: - Run state

    enum RunState: String { case idle, running, paused, completed }

    private(set) var state: RunState = .idle

    /// The intervals for the active session and a precomputed timeline.
    private(set) var intervals: [Interval] = []
    /// Cumulative end-second of each interval (timeline boundaries).
    private var cumulativeEnds: [Int] = []
    /// Total session length in seconds (guarded to be ≥ 0).
    private(set) var totalSeconds: Int = 0

    /// Wall-clock anchor: when the (current) run segment started.
    private var segmentStart: Date?
    /// Accumulated elapsed seconds from previous run segments (before the last pause).
    private var accumulated: TimeInterval = 0

    /// Identifies which plan/session this run belongs to, for completion + restore.
    private(set) var planId: String = ""
    private(set) var sessionId: String = ""
    private(set) var week: Int = 1
    private(set) var sessionIndex: Int = 0

    /// The highest interval index for which we've already fired the "begin" cue.
    private var lastAnnouncedIndex: Int = -1
    /// The last whole-second remaining for which we fired a countdown beep.
    private var lastBeepSecond: Int = -1

    // MARK: - Dependencies

    private let cues = AudioCues()
    private let store: ActiveRunStore

    // Cue preferences, refreshed by the view before each transition check.
    var voiceCuesEnabled = true
    var countdownBeepsEnabled = true
    var hapticsEnabled = true

    init(store: ActiveRunStore = ActiveRunStore()) {
        self.store = store
    }

    // MARK: - Derived, wall-clock state

    /// Elapsed seconds, derived from anchors. Never exceeds total.
    func elapsed(now: Date) -> TimeInterval {
        let live: TimeInterval
        if state == .running, let start = segmentStart {
            live = accumulated + now.timeIntervalSince(start)
        } else {
            live = accumulated
        }
        return min(Double(totalSeconds), max(0, live))
    }

    /// Index of the current interval for a given elapsed time. Guarded for empty lists.
    func currentIndex(now: Date) -> Int {
        guard !cumulativeEnds.isEmpty else { return 0 }
        let e = elapsed(now: now)
        for (i, end) in cumulativeEnds.enumerated() where e < Double(end) {
            return i
        }
        return cumulativeEnds.count - 1
    }

    func currentInterval(now: Date) -> Interval? {
        intervals[safe: currentIndex(now: now)]
    }

    func nextInterval(now: Date) -> Interval? {
        intervals[safe: currentIndex(now: now) + 1]
    }

    /// Seconds remaining in the current interval (≥ 0).
    func intervalRemaining(now: Date) -> Int {
        let idx = currentIndex(now: now)
        guard let end = cumulativeEnds[safe: idx] else { return 0 }
        return max(0, Int(ceil(Double(end) - elapsed(now: now))))
    }

    /// Progress fraction within the current interval (0...1), division-guarded.
    func intervalProgress(now: Date) -> Double {
        let idx = currentIndex(now: now)
        guard let interval = intervals[safe: idx], interval.durationSeconds > 0,
              let end = cumulativeEnds[safe: idx] else { return 0 }
        let start = end - interval.durationSeconds
        let into = elapsed(now: now) - Double(start)
        return min(1.0, max(0.0, into / Double(interval.durationSeconds)))
    }

    /// Overall remaining seconds (≥ 0).
    func overallRemaining(now: Date) -> Int {
        max(0, totalSeconds - Int(elapsed(now: now)))
    }

    /// Overall progress fraction (0...1), division-guarded.
    func overallProgress(now: Date) -> Double {
        guard totalSeconds > 0 else { return 0 }
        return min(1.0, max(0.0, elapsed(now: now) / Double(totalSeconds)))
    }

    /// Whether the session has reached its end.
    func isComplete(now: Date) -> Bool {
        totalSeconds > 0 && elapsed(now: now) >= Double(totalSeconds)
    }

    /// Whether the current interval is the final one.
    func isFinalInterval(now: Date) -> Bool {
        !intervals.isEmpty && currentIndex(now: now) == intervals.count - 1
    }

    /// Run seconds elapsed so far (for the completion record), guarded.
    func runSecondsElapsed(now: Date) -> Int {
        let e = elapsed(now: now)
        var total = 0
        var cursor = 0
        for interval in intervals {
            let segEnd = cursor + interval.durationSeconds
            if interval.kind.isRunning {
                let covered = min(Double(segEnd), e) - Double(cursor)
                if covered > 0 { total += Int(covered) }
            }
            cursor = segEnd
        }
        return max(0, total)
    }

    // MARK: - Lifecycle

    /// Begin a fresh session. Builds the timeline and persists the start anchor.
    func start(plan: TrainingPlan, session: PlanSession, week: Int, sessionIndex: Int) {
        load(intervals: session.intervals,
             planId: plan.id, sessionId: session.id,
             week: week, sessionIndex: sessionIndex)
        guard !intervals.isEmpty else { state = .completed; return }

        accumulated = 0
        segmentStart = Date()
        state = .running
        lastAnnouncedIndex = -1
        lastBeepSecond = -1
        persist()
        // Announce the very first interval immediately.
        announceTransitionsIfNeeded(now: Date())
    }

    /// Build timeline data from intervals. Shared by start() and restore().
    private func load(intervals: [Interval], planId: String, sessionId: String, week: Int, sessionIndex: Int) {
        self.intervals = intervals
        self.planId = planId
        self.sessionId = sessionId
        self.week = max(1, week)
        self.sessionIndex = max(0, sessionIndex)

        var running = 0
        var ends: [Int] = []
        for interval in intervals {
            running += interval.durationSeconds
            ends.append(running)
        }
        cumulativeEnds = ends
        totalSeconds = running
    }

    func pause() {
        guard state == .running, let start = segmentStart else { return }
        accumulated += Date().timeIntervalSince(start)
        segmentStart = nil
        state = .paused
        cues.stop()
        persist()
    }

    func resume() {
        guard state == .paused else { return }
        segmentStart = Date()
        state = .running
        persist()
    }

    /// Stop and discard the active run (no completion recorded).
    func stop() {
        cues.stop()
        cues.deactivate()
        clearState()
    }

    /// Mark complete (called when elapsed reaches total). Idempotent.
    func markCompleted() {
        guard state != .completed else { return }
        accumulated = Double(totalSeconds)
        segmentStart = nil
        state = .completed
        cues.transitionTone(enabled: countdownBeepsEnabled)
        cues.speak("Workout complete. Great job.", enabled: voiceCuesEnabled)
        Haptics.success(hapticsEnabled)
        store.clear()
    }

    private func clearState() {
        state = .idle
        intervals = []
        cumulativeEnds = []
        totalSeconds = 0
        accumulated = 0
        segmentStart = nil
        lastAnnouncedIndex = -1
        lastBeepSecond = -1
        store.clear()
    }

    // MARK: - Tick (called by the TimelineView each refresh)

    /// Drive cues & completion from the current wall-clock moment. Pure w.r.t.
    /// derived state; only side effects are audio/haptics and the completed flag.
    func tick(now: Date) {
        guard state == .running else { return }
        if isComplete(now: now) {
            markCompleted()
            return
        }
        announceTransitionsIfNeeded(now: now)
        announceCountdownIfNeeded(now: now)
    }

    /// Fire a spoken cue + haptic when entering a new interval.
    private func announceTransitionsIfNeeded(now: Date) {
        let idx = currentIndex(now: now)
        guard idx > lastAnnouncedIndex else { return }
        lastAnnouncedIndex = idx
        lastBeepSecond = -1
        guard let interval = intervals[safe: idx] else { return }

        // "Last interval" pre-roll for the final block (unless it's a cooldown,
        // which already speaks "cool down").
        if idx == intervals.count - 1 && interval.kind != .cooldown && intervals.count > 1 {
            cues.speak("Last interval. " + interval.kind.spokenCue, enabled: voiceCuesEnabled)
        } else {
            cues.speak(interval.kind.spokenCue, enabled: voiceCuesEnabled)
        }
        cues.transitionTone(enabled: countdownBeepsEnabled)
        switch interval.kind {
        case .run:      Haptics.heavy(hapticsEnabled)
        case .cooldown: Haptics.medium(hapticsEnabled)
        default:        Haptics.medium(hapticsEnabled)
        }
    }

    /// Beep once per second in the final 3 seconds of an interval.
    private func announceCountdownIfNeeded(now: Date) {
        guard countdownBeepsEnabled else { return }
        let remaining = intervalRemaining(now: now)
        // Don't beep the final boundary of the whole session here — completion handles it.
        guard remaining >= 1 && remaining <= 3 else { return }
        guard remaining != lastBeepSecond else { return }
        lastBeepSecond = remaining
        cues.beep(enabled: true)
    }

    // MARK: - Persistence / restore

    private func persist() {
        guard state == .running || state == .paused else { return }
        let snap = ActiveRunSnapshot(
            planId: planId,
            sessionId: sessionId,
            week: week,
            sessionIndex: sessionIndex,
            startDate: segmentStart ?? Date(),
            accumulated: accumulated,
            isPaused: state == .paused
        )
        store.save(snap)
    }

    /// Attempt to restore an in-progress run from disk. Returns true if a run was
    /// resumed. Re-derives elapsed from the persisted start `Date` so the timer is
    /// correct even after a long background or relaunch.
    @discardableResult
    func restoreIfNeeded() -> Bool {
        guard state == .idle, let snap = store.load() else { return false }
        guard let plan = PlanResolver.shared.plan(id: snap.planId),
              let session = plan.flatSessions.first(where: { $0.session.id == snap.sessionId })?.session else {
            store.clear()
            return false
        }
        load(intervals: session.intervals,
             planId: snap.planId, sessionId: snap.sessionId,
             week: snap.week, sessionIndex: snap.sessionIndex)
        guard !intervals.isEmpty else { store.clear(); return false }

        if snap.isPaused {
            accumulated = max(0, snap.accumulated)
            segmentStart = nil
            state = .paused
        } else {
            // Running: accumulated is fixed; segmentStart continues from the stored date.
            accumulated = max(0, snap.accumulated)
            segmentStart = snap.startDate
            state = .running
        }
        // Bring the announce cursor up to the restored position so we don't
        // re-announce every interval already passed.
        lastAnnouncedIndex = currentIndex(now: Date())
        lastBeepSecond = -1

        if isComplete(now: Date()) {
            markCompleted()
        }
        return true
    }

    /// Recompute on scene-phase change. With a wall-clock model nothing needs
    /// adjusting, but we re-check completion so a run that finished while
    /// backgrounded surfaces its success screen.
    func handleScenePhaseActive() {
        guard state == .running else { return }
        if isComplete(now: Date()) { markCompleted() }
    }

    /// Release audio when the player view disappears without completing.
    func releaseAudio() {
        cues.deactivate()
    }
}
