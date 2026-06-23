import Foundation
import SwiftUI
import Observation

/// Drives a single focus/break run. Date-based so it stays accurate across
/// pause/resume and view re-renders; the View ticks it from a TimelineView.
@MainActor
@Observable
final class TimerEngine {

    enum Phase: String { case focus, shortBreak, longBreak }
    enum RunState { case idle, running, paused, finished }

    // Configuration for the current run.
    private(set) var mode: SessionMode = .pomodoro
    private(set) var phase: Phase = .focus
    /// Planned focus length in seconds (0 = open-ended flow).
    private(set) var plannedSeconds: Int = 25 * 60
    private(set) var breakSeconds: Int = 5 * 60
    private(set) var roundsBeforeLong: Int = 4
    private(set) var completedFocusRounds: Int = 0

    private(set) var state: RunState = .idle
    private(set) var distractionCount: Int = 0

    // Time accounting.
    private var phaseStart: Date = .now
    /// Accumulated focused time before the current running segment (handles pauses).
    private var accumulated: TimeInterval = 0

    // Session context.
    var selectedTag: String = ""
    var note: String = ""

    // MARK: - Derived values (computed against a supplied "now" for TimelineView)

    /// Elapsed seconds in the current phase at the given moment.
    func elapsed(at now: Date) -> Int {
        let live = state == .running ? now.timeIntervalSince(phaseStart) : 0
        return max(0, Int(accumulated + live))
    }

    /// Remaining seconds (focus or break). For open-ended flow, returns elapsed (counts up).
    func remaining(at now: Date) -> Int {
        if isOpenEnded { return elapsed(at: now) }
        return max(0, targetSeconds - elapsed(at: now))
    }

    /// Progress 0...1 for the ring. Flow phases pulse but cap at a soft 1.0.
    func progress(at now: Date) -> Double {
        if isOpenEnded {
            // Visual breathing scale: fill over a notional 60-min window, capped.
            return min(1.0, Double(elapsed(at: now)) / Double(60 * 60))
        }
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsed(at: now)) / Double(targetSeconds))
    }

    var isOpenEnded: Bool { phase == .focus && mode == .flow }

    var isBreak: Bool { phase != .focus }

    private var targetSeconds: Int {
        phase == .focus ? plannedSeconds : breakSeconds
    }

    /// Has a fixed-length phase reached its target? (Caller checks each tick.)
    func hasReachedTarget(at now: Date) -> Bool {
        guard !isOpenEnded else { return false }
        return elapsed(at: now) >= targetSeconds && state == .running
    }

    // MARK: - Lifecycle

    func configure(mode: SessionMode,
                   focusMinutes: Int,
                   breakMinutes: Int,
                   roundsBeforeLong: Int,
                   tag: String) {
        self.mode = mode
        self.phase = .focus
        self.plannedSeconds = mode == .flow ? 0 : max(60, focusMinutes * 60)
        self.breakSeconds = max(60, breakMinutes * 60)
        self.roundsBeforeLong = max(1, roundsBeforeLong)
        self.selectedTag = tag
        self.note = ""
        self.completedFocusRounds = 0
        self.distractionCount = 0
        reset()
    }

    func start() {
        guard state == .idle || state == .paused else { return }
        phaseStart = .now
        state = .running
    }

    func pause() {
        guard state == .running else { return }
        accumulated += Date().timeIntervalSince(phaseStart)
        state = .paused
    }

    func resume() {
        guard state == .paused else { return }
        phaseStart = .now
        state = .running
    }

    func addDistraction() {
        guard phase == .focus else { return }
        distractionCount += 1
    }

    private func reset() {
        accumulated = 0
        phaseStart = .now
        state = .idle
    }

    // MARK: - Phase transitions

    /// Snapshot of a focus phase that just finished, for persistence.
    struct FocusResult {
        let startedAt: Date
        let endedAt: Date
        let focusedSeconds: Int
        let plannedSeconds: Int
        let mode: SessionMode
        let distractionCount: Int
        let completed: Bool
    }

    /// Finalize the current focus phase, returning a result if it was a focus phase
    /// worth logging (≥ 1 second of focus). Advances internal round counter.
    func finalizeFocus(at now: Date, completed: Bool) -> FocusResult? {
        guard phase == .focus else { return nil }
        let focused = elapsed(at: now)
        let started = now.addingTimeInterval(-Double(focused))
        // Open-ended flow with < 60s isn't worth logging.
        let worthLogging = focused >= 1
        if completed { completedFocusRounds += 1 }
        let result = worthLogging ? FocusResult(
            startedAt: started,
            endedAt: now,
            focusedSeconds: focused,
            plannedSeconds: plannedSeconds,
            mode: mode,
            distractionCount: distractionCount,
            completed: completed
        ) : nil
        return result
    }

    /// Move into the appropriate break phase. Returns the break length in minutes.
    func beginBreak(longBreakMinutes: Int, shortBreakMinutes: Int) {
        let isLong = completedFocusRounds > 0 && completedFocusRounds % roundsBeforeLong == 0
        phase = isLong ? .longBreak : .shortBreak
        breakSeconds = max(60, (isLong ? longBreakMinutes : shortBreakMinutes) * 60)
        accumulated = 0
        phaseStart = .now
        state = .running
    }

    /// Return to a fresh focus phase (next round).
    func beginNextFocus() {
        phase = .focus
        distractionCount = 0
        accumulated = 0
        phaseStart = .now
        state = .idle
    }

    /// Fully stop the run.
    func stop() {
        state = .finished
    }

    func returnToIdle() {
        phase = .focus
        accumulated = 0
        phaseStart = .now
        state = .idle
        distractionCount = 0
        completedFocusRounds = 0
    }
}
