import Foundation
import SwiftUI
import Combine

/// The state that must survive backgrounding and relaunch, encoded as JSON in a
/// single @AppStorage string. We persist absolute end Dates so the countdown can
/// be reconstructed exactly regardless of how long the app was away.
struct TimerState: Codable, Equatable {
    var phases: [Phase]
    var currentIndex: Int
    var phaseEnd: Date          // absolute end of the current phase (when running)
    var isPaused: Bool
    var remainingWhenPaused: Int   // seconds remaining, valid only while paused
    /// Snapshot of setup so a completed run can be saved to the log.
    var recipeName: String
    var filmStock: String
    var developer: String
    var dilution: String
    var ei: Int
    var tempC: Double
    var pushPull: Int
    var recipeID: UUID?
}

/// Drives the four-phase developing timer. Relaunch-safe: all timing derives from
/// the persisted `TimerState` (absolute end Date), so the visible countdown is
/// correct even after the app was backgrounded or fully relaunched. The 1 Hz
/// SwiftUI tick is only a display heartbeat — never the source of truth.
@MainActor
final class TimerEngine: ObservableObject {

    /// JSON blob persisted across launches.
    @AppStorage("latent.timer.state") private var stored: String = ""

    /// Whether to keep the screen awake while a timer is running.
    @AppStorage("latent.keepAwake") private var keepAwake: Bool = true

    /// Default agitation interval (seconds) — read at start time.
    @AppStorage("latent.agitationInterval") private var agitationInterval: Int = 60

    @Published private(set) var state: TimerState?
    /// Display-only heartbeat that forces recomputation each second.
    @Published private(set) var now: Date = Date()

    /// Visual pulse trigger for agitation reminders (toggles each reminder).
    @Published var agitationPulse: Bool = false
    /// Set true on the tick a phase finishes (for completion handling in the view).
    @Published private(set) var didComplete: Bool = false

    private var ticker: AnyCancellable?
    private var lastAgitationBucket: Int = -1

    init() {
        restore()
    }

    // MARK: - Derived display values

    var isRunning: Bool { state != nil && !(state?.isPaused ?? true) }
    var isActive: Bool { state != nil }
    var isPaused: Bool { state?.isPaused ?? false }

    var currentPhase: Phase? {
        guard let s = state, s.phases.indices.contains(s.currentIndex) else { return nil }
        return s.phases[s.currentIndex]
    }

    var nextPhase: Phase? {
        guard let s = state else { return nil }
        let n = s.currentIndex + 1
        return s.phases.indices.contains(n) ? s.phases[n] : nil
    }

    /// Seconds remaining in the current phase, derived from persisted state.
    var remainingSec: Int {
        guard let s = state else { return 0 }
        if s.isPaused { return max(0, s.remainingWhenPaused) }
        return max(0, Int(s.phaseEnd.timeIntervalSince(now).rounded(.up)))
    }

    /// Fraction elapsed of the current phase, 0…1.
    var phaseProgress: Double {
        guard let phase = currentPhase, phase.seconds > 0 else { return 0 }
        let elapsed = Double(phase.seconds - remainingSec)
        return min(1, max(0, elapsed / Double(phase.seconds)))
    }

    /// Seconds remaining across the whole run (current phase + all later phases).
    var totalRemainingSec: Int {
        guard let s = state else { return 0 }
        var total = remainingSec
        var i = s.currentIndex + 1
        while s.phases.indices.contains(i) {
            total += s.phases[i].seconds
            i += 1
        }
        return total
    }

    // MARK: - Lifecycle

    /// Begin a fresh run from a built phase plan and setup snapshot.
    func start(phases: [Phase], setupFrom session: PendingRun) {
        guard let first = phases.first else { return }
        let end = Date().addingTimeInterval(TimeInterval(first.seconds))
        state = TimerState(
            phases: phases,
            currentIndex: 0,
            phaseEnd: end,
            isPaused: false,
            remainingWhenPaused: first.seconds,
            recipeName: session.recipeName,
            filmStock: session.filmStock,
            developer: session.developer,
            dilution: session.dilution,
            ei: session.ei,
            tempC: session.tempC,
            pushPull: session.pushPull,
            recipeID: session.recipeID
        )
        didComplete = false
        lastAgitationBucket = -1
        persist()
        applyIdleTimer()
        startTicker()
        Haptics.success()
    }

    func pause() {
        guard var s = state, !s.isPaused else { return }
        s.remainingWhenPaused = remainingSec
        s.isPaused = true
        state = s
        persist()
        applyIdleTimer()
        Haptics.tap()
    }

    func resume() {
        guard var s = state, s.isPaused else { return }
        s.phaseEnd = Date().addingTimeInterval(TimeInterval(max(0, s.remainingWhenPaused)))
        s.isPaused = false
        state = s
        now = Date()
        persist()
        applyIdleTimer()
        Haptics.tap()
    }

    /// Advance to the next phase, or complete if this was the last.
    func skip() {
        advance(isSkip: true)
    }

    func cancel() {
        state = nil
        stored = ""
        didComplete = false
        stopTicker()
        applyIdleTimer()
        Haptics.warning()
    }

    /// Clears state after a completed run has been saved or dismissed.
    func finishAndClear() {
        state = nil
        stored = ""
        didComplete = false
        stopTicker()
        applyIdleTimer()
    }

    // MARK: - Ticking

    func onAppear() {
        restore()
        now = Date()
        if isActive { startTicker(); applyIdleTimer() }
        // Catch up any phase boundaries crossed while away.
        catchUp()
    }

    func onDisappear() {
        // Keep state; just stop the display ticker. State already persisted.
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func stopTicker() {
        ticker?.cancel()
        ticker = nil
    }

    private func tick() {
        now = Date()
        guard let s = state, !s.isPaused else { return }

        // Agitation reminder: pulse + light haptic each interval boundary.
        if let phase = currentPhase, phase.agitationEverySec > 0, phase.seconds > 0 {
            let elapsed = phase.seconds - remainingSec
            if elapsed > 0 && remainingSec > 0 {
                let bucket = elapsed / phase.agitationEverySec
                if bucket > 0 && bucket != lastAgitationBucket {
                    lastAgitationBucket = bucket
                    agitationPulse.toggle()
                    Haptics.tap()
                }
            }
        }

        if remainingSec <= 0 {
            advance(isSkip: false)
        }
    }

    /// Reconstruct any phase ends crossed while backgrounded/relaunched.
    private func catchUp() {
        guard var s = state, !s.isPaused else { return }
        // Roll forward through completed phases using their durations.
        while s.phases.indices.contains(s.currentIndex) {
            let rem = Int(s.phaseEnd.timeIntervalSince(Date()).rounded(.up))
            if rem > 0 { break }
            // This phase ended; move to next, anchoring its end to the prior end.
            let next = s.currentIndex + 1
            if s.phases.indices.contains(next) {
                let overrun = -rem  // how far past the boundary we are
                let nextDur = s.phases[next].seconds
                s.currentIndex = next
                s.phaseEnd = Date().addingTimeInterval(TimeInterval(max(0, nextDur - overrun)))
                s.remainingWhenPaused = nextDur
                lastAgitationBucket = -1
            } else {
                // Whole run already finished while away.
                s.currentIndex = s.phases.count - 1
                state = s
                completeRun()
                return
            }
        }
        state = s
        persist()
    }

    private func advance(isSkip: Bool) {
        guard var s = state else { return }
        let next = s.currentIndex + 1
        if s.phases.indices.contains(next) {
            s.currentIndex = next
            let dur = s.phases[next].seconds
            s.isPaused = false
            s.phaseEnd = Date().addingTimeInterval(TimeInterval(dur))
            s.remainingWhenPaused = dur
            state = s
            now = Date()
            lastAgitationBucket = -1
            persist()
            Haptics.success()
        } else {
            state = s
            completeRun()
        }
    }

    private func completeRun() {
        didComplete = true
        stopTicker()
        applyIdleTimer()
        Haptics.success()
    }

    // MARK: - Persistence

    private func persist() {
        guard let s = state else { stored = ""; return }
        if let data = try? JSONEncoder().encode(s),
           let json = String(data: data, encoding: .utf8) {
            stored = json
        }
    }

    private func restore() {
        guard !stored.isEmpty,
              let data = stored.data(using: .utf8),
              let s = try? JSONDecoder().decode(TimerState.self, from: data) else {
            state = nil
            return
        }
        state = s
    }

    // MARK: - Screen wake

    private func applyIdleTimer() {
        let shouldStayAwake = keepAwake && isRunning
        UIApplication.shared.isIdleTimerDisabled = shouldStayAwake
    }
}

/// The setup snapshot handed to the engine when a run begins.
struct PendingRun {
    var recipeName: String
    var filmStock: String
    var developer: String
    var dilution: String
    var ei: Int
    var tempC: Double
    var pushPull: Int
    var recipeID: UUID?
}
