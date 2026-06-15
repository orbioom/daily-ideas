import SwiftUI
import UIKit

/// Drives an active ringing session: which alarm is firing, snooze accounting, the ramping
/// tone (via `RingEngine`), the repeating ring vibration, and writing the `WakeLog` on
/// successful dismiss. Presented full-screen by `RootView` whenever `activeAlarm != nil`.
@MainActor
final class RingController: ObservableObject {

    /// The alarm currently ringing (real or a test). `nil` = nothing is ringing.
    @Published private(set) var activeAlarm: AlarmSnapshot?
    /// When the current ring started (for the WakeLog time-to-dismiss).
    @Published private(set) var firedAt: Date = Date()
    /// How many times the user has snoozed this ring.
    @Published private(set) var snoozeCount: Int = 0
    /// True while this is a test/preview ring (so we don't pollute stats with test wakes).
    @Published private(set) var isTest: Bool = false

    private let ringEngine = RingEngine()
    private var vibrateTimer: Timer?
    private var snoozeTimer: Timer?
    private weak var settings: AppSettings?

    /// Inject settings once (from RootView) so we honor vibrate/haptics/keep-screen prefs.
    func configure(settings: AppSettings) {
        self.settings = settings
    }

    var isRinging: Bool { activeAlarm != nil }

    // MARK: Start / snooze / stop

    /// Begin ringing for an alarm. `test` rings without writing a WakeLog and skips the ramp.
    func startRinging(_ alarm: Alarm, test: Bool = false) {
        // Snapshot the alarm's values so the ring screen never touches a possibly-deleted model.
        let snapshot = AlarmSnapshot(alarm: alarm)
        activeAlarm = snapshot
        firedAt = Date()
        snoozeCount = 0
        isTest = test
        beginAudioAndHaptics(snapshot: snapshot, test: test)
        keepScreenAwake(true)
    }

    /// Snooze: silence for `snoozeMinutes`, then ring again. Capped by `maxSnoozes`.
    func snooze() {
        guard let snapshot = activeAlarm, canSnooze else { return }
        snoozeCount += 1
        Haptics.thump(settings?.hapticsEnabled ?? false)
        stopAudioAndHaptics()
        let minutes = max(1, snapshot.snoozeMinutes)
        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60.0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.resumeFromSnooze() }
        }
    }

    /// Demo-friendly quick snooze used by the "Preview" flow (rings again in 5 seconds).
    func snoozeQuick() {
        guard let _ = activeAlarm, canSnooze else { return }
        snoozeCount += 1
        Haptics.thump(settings?.hapticsEnabled ?? false)
        stopAudioAndHaptics()
        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.resumeFromSnooze() }
        }
    }

    private func resumeFromSnooze() {
        guard let snapshot = activeAlarm else { return }
        beginAudioAndHaptics(snapshot: snapshot, test: isTest)
    }

    var canSnooze: Bool {
        guard let s = activeAlarm else { return false }
        return s.snoozeEnabled && snoozeCount < s.maxSnoozes
    }

    var snoozesRemaining: Int {
        guard let s = activeAlarm else { return 0 }
        return max(0, s.maxSnoozes - snoozeCount)
    }

    /// Successfully dismissed (mission complete). Writes a WakeLog (unless test) via callback.
    /// Returns the WakeLog to insert, or nil for a test ring.
    @discardableResult
    func dismiss() -> WakeLog? {
        let snapshot = activeAlarm
        let fired = firedAt
        let snoozes = snoozeCount
        let test = isTest
        teardown()
        guard let snapshot, !test else { return nil }
        return WakeLog(alarmLabel: snapshot.label,
                       firedAt: fired,
                       dismissedAt: Date(),
                       snoozeCount: snoozes,
                       missionType: snapshot.missionType)
    }

    /// Cancel the ring without recording a wake (used when dismissing a test, or backing out).
    func cancel() {
        teardown()
    }

    // MARK: Internal audio/haptics

    private func beginAudioAndHaptics(snapshot: AlarmSnapshot, test: Bool) {
        let ramp = test ? 3 : snapshot.volumeRampSeconds
        ringEngine.start(soundName: snapshot.soundName, rampSeconds: ramp, preview: false)
        startVibration()
    }

    private func stopAudioAndHaptics() {
        ringEngine.stop()
        stopVibration()
    }

    private func teardown() {
        stopAudioAndHaptics()
        snoozeTimer?.invalidate(); snoozeTimer = nil
        keepScreenAwake(false)
        activeAlarm = nil
        snoozeCount = 0
        isTest = false
    }

    private func startVibration() {
        guard settings?.vibrateOnRing ?? false else { return }
        vibrateTimer?.invalidate()
        // Pulse a noticeable haptic every ~2.5s while ringing.
        Haptics.thump(settings?.hapticsEnabled ?? true)
        vibrateTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            Task { @MainActor in
                let gen = UIImpactFeedbackGenerator(style: .heavy)
                gen.impactOccurred()
            }
        }
    }

    private func stopVibration() {
        vibrateTimer?.invalidate()
        vibrateTimer = nil
    }

    private func keepScreenAwake(_ on: Bool) {
        guard settings?.keepScreenOn ?? true else {
            UIApplication.shared.isIdleTimerDisabled = false
            return
        }
        UIApplication.shared.isIdleTimerDisabled = on
    }
}

/// An immutable snapshot of an alarm's ring-relevant fields, decoupled from the SwiftData model
/// so the Ring screen can never crash on a deleted/changed object.
struct AlarmSnapshot: Identifiable, Equatable {
    let id: UUID
    let label: String
    let soundName: String
    let missionType: MissionType
    let missionDifficulty: MissionDifficulty
    let missionReps: Int
    let snoozeEnabled: Bool
    let snoozeMinutes: Int
    let maxSnoozes: Int
    let volumeRampSeconds: Int

    init(alarm: Alarm) {
        self.id = alarm.id
        self.label = alarm.label
        self.soundName = alarm.soundName
        self.missionType = alarm.missionType
        self.missionDifficulty = alarm.missionDifficulty
        self.missionReps = MissionEngine.effectiveReps(for: alarm.missionType, requested: alarm.missionReps)
        self.snoozeEnabled = alarm.snoozeEnabled
        self.snoozeMinutes = max(1, alarm.snoozeMinutes)
        self.maxSnoozes = max(0, alarm.maxSnoozes)
        self.volumeRampSeconds = max(0, alarm.volumeRampSeconds)
    }
}
