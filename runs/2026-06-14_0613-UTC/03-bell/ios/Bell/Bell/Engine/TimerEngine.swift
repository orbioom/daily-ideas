import Foundation
import SwiftUI

/// Live meditation timer. Date-based so backgrounding / lock never drifts the
/// clock — elapsed is always computed from `Date()`. Interval bells are
/// reconciled on every tick so any that "should have rung" while backgrounded
/// fire on return. A `final class` ObservableObject owned via `@StateObject`.
@MainActor
final class TimerEngine: ObservableObject {

    enum Phase: Equatable {
        case idle
        case warmup
        case sitting
        case paused
        case complete
    }

    // MARK: - Published UI state
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var elapsedSec: Int = 0
    @Published private(set) var remainingSec: Int = 0
    @Published private(set) var intervalBellsRung: Int = 0
    /// True once `start` runs but audio could not be brought up — UI can show a
    /// gentle "silent mode" note.
    @Published private(set) var silentMode = false

    // MARK: - Configuration (captured at start)
    private(set) var preset: Preset?
    private var durationSec: Int = 0      // 0 == open-ended
    private var warmupSec: Int = 0
    private var intervalSec: Int = 0      // 0 == no interval bells
    private var bell: BellTone = .bowl
    private var ambient: Ambient = .none

    var isOpenEnded: Bool { durationSec == 0 }

    // MARK: - Timekeeping
    private var sessionStartDate: Date?
    /// Accumulated active seconds before the current resume (for pause support).
    private var accumulatedBeforePause: TimeInterval = 0
    private var resumeDate: Date?

    private weak var sound: SoundEngine?
    private var settings: AppSettings?
    private var ticker: Timer?

    // MARK: - Setup

    func configure(sound: SoundEngine, settings: AppSettings) {
        self.sound = sound
        self.settings = settings
    }

    /// Begin a sit from a preset. Brings audio up gracefully (silent on failure).
    func start(with preset: Preset) {
        self.preset = preset
        durationSec = max(0, preset.durationMin) * 60
        warmupSec = max(0, preset.warmupSec)
        intervalSec = max(0, preset.intervalMin) * 60
        bell = preset.bellValue
        ambient = preset.ambientValue

        accumulatedBeforePause = 0
        intervalBellsRung = 0
        elapsedSec = 0
        remainingSec = durationSec

        let now = Date()
        sessionStartDate = now
        resumeDate = now
        phase = warmupSec > 0 ? .warmup : .sitting

        // Audio is best-effort. Any failure => silent mode + haptic cues.
        if let sound, settings?.soundEnabled == true {
            let ok = sound.start()
            silentMode = !ok
            if ok, ambient != .none {
                sound.startAmbient(ambient)
            }
        } else {
            silentMode = settings?.soundEnabled == false ? false : true
        }

        // Keep screen awake per setting.
        if settings?.keepScreenAwake == true {
            UIApplication.shared.isIdleTimerDisabled = true
        }

        startTicker()
        tick() // immediate first update
    }

    func pause() {
        guard phase == .warmup || phase == .sitting else { return }
        // Bank the active time accrued since last resume.
        if let resumeDate {
            accumulatedBeforePause += Date().timeIntervalSince(resumeDate)
        }
        resumeDate = nil
        phase = .paused
        sound?.fadeAmbient(to: 0.04, over: 0.6)
    }

    func resume() {
        guard phase == .paused else { return }
        resumeDate = Date()
        // Resume into warmup or sitting depending on elapsed.
        phase = activeSeconds() < Double(warmupSec) ? .warmup : .sitting
        if ambient != .none { sound?.startAmbient(ambient) }
    }

    /// Active (non-paused) seconds since the sit began.
    private func activeSeconds() -> TimeInterval {
        var total = accumulatedBeforePause
        if let resumeDate { total += Date().timeIntervalSince(resumeDate) }
        return max(0, total)
    }

    private func startTicker() {
        ticker?.invalidate()
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func tick() {
        guard phase != .idle, phase != .complete else { return }
        if phase == .paused {
            // Freeze the displayed values while paused.
            return
        }

        let active = activeSeconds()
        elapsedSec = Int(active)

        // Phase transition warmup -> sitting.
        if phase == .warmup, active >= Double(warmupSec) {
            phase = .sitting
            // Opening bell marks the start of the sit proper.
            ringBell()
        }

        // Interval bells (only during the sit body, excluding warmup window).
        if intervalSec > 0, phase == .sitting {
            let sittingElapsed = active - Double(warmupSec)
            if sittingElapsed > 0 {
                let due = Int(sittingElapsed) / intervalSec
                // Don't double-ring the final bell if it lands exactly at the end.
                while intervalBellsRung < due {
                    intervalBellsRung += 1
                    ringBell()
                }
            }
        }

        // Countdown / completion.
        if !isOpenEnded {
            let totalTarget = Double(durationSec + warmupSec)
            remainingSec = max(0, Int(totalTarget - active))
            if active >= totalTarget {
                finish()
            }
        }
    }

    /// Ring the configured bell, degrading to a haptic cue in silent mode.
    private func ringBell() {
        if let sound, sound.isAvailable, settings?.soundEnabled == true {
            let rang = sound.ringBell(bell)
            if !rang { Haptics.bellCue(enabled: settings?.hapticsEnabled ?? false) }
        } else {
            Haptics.bellCue(enabled: settings?.hapticsEnabled ?? false)
        }
    }

    /// End the sit naturally — ending bell, fade ambient, mark complete.
    private func finish() {
        guard phase != .complete else { return }
        phase = .complete
        ticker?.invalidate(); ticker = nil
        ringBell()
        sound?.fadeAmbient(to: 0, over: 1.5)
        Haptics.success(enabled: settings?.hapticsEnabled ?? false)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    /// End early by the user. Returns the actual seconds sat so the caller can
    /// save a session. `completedFully` is false here.
    @discardableResult
    func endEarly() -> Int {
        let sat = Int(activeSeconds())
        phase = .complete
        ticker?.invalidate(); ticker = nil
        sound?.fadeAmbient(to: 0, over: 0.8)
        UIApplication.shared.isIdleTimerDisabled = false
        return max(0, sat)
    }

    /// Seconds actually sat (used when building the saved session).
    var sittingSeconds: Int {
        // Exclude the warmup window from "minutes sat".
        max(0, Int(activeSeconds()) - warmupSec)
    }

    /// Full teardown — call on dismissal.
    func teardown() {
        ticker?.invalidate(); ticker = nil
        sound?.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        phase = .idle
    }

    // MARK: - Display helpers

    var phaseLabel: String {
        switch phase {
        case .idle: return "Ready"
        case .warmup: return "Settling in"
        case .sitting: return "Sitting"
        case .paused: return "Paused"
        case .complete: return "Complete"
        }
    }

    /// What the big clock should read.
    var clockSeconds: Int { isOpenEnded ? elapsedSec : remainingSec }

    /// 0...1 progress through the configured sit (for the ring). Open-ended
    /// sits breathe on a 1-minute visual cycle instead.
    var progress: Double {
        if isOpenEnded {
            let cycle = 60.0
            return (Double(elapsedSec).truncatingRemainder(dividingBy: cycle)) / cycle
        }
        let total = Double(durationSec + warmupSec)
        guard total > 0 else { return 0 }
        return min(1, Double(elapsedSec) / total)
    }
}
