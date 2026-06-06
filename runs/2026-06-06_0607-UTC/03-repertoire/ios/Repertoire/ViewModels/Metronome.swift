import SwiftUI
import Observation
import AudioToolbox
import UIKit

/// A calm, drift-resistant metronome.
///
/// Rather than an `AVAudioEngine` source node (which risks audio-session setup and
/// missing buffers), the beat is driven by a `Date`-based `@MainActor` scheduler: a
/// repeating high-tolerance timer wakes us, and on each wake we emit every beat whose
/// scheduled instant has passed. The visual pulse, a haptic, and an optional soft
/// system tick fire together. BPM is always bounded to 20…300.
@MainActor
@Observable
final class Metronome {

    /// Beats per minute, always within `Tempo.min...Tempo.max`.
    private(set) var bpm: Int
    private(set) var isRunning: Bool = false

    /// Toggled true→false each beat so views can animate a pulse off the change.
    private(set) var beatToggle: Bool = false
    /// Monotonic count of beats since the metronome last started.
    private(set) var beatCount: Int = 0

    /// Whether a soft system tick plays alongside the haptic/visual beat.
    var soundEnabled: Bool = true
    /// Whether the beat haptic fires (also gated by the global haptics setting at the call site).
    var hapticsEnabled: Bool = true

    private var timer: Timer?
    private var nextBeat: Date = .now
    private var beatGenerator: UIImpactFeedbackGenerator?

    /// Recent tap timestamps for tap-tempo averaging.
    private var taps: [Date] = []

    /// A soft, short system sound id used for the tick (1104 = a gentle keyboard tap tone).
    private let tickSoundID: SystemSoundID = 1104

    init(bpm: Int = 80) {
        self.bpm = Tempo.clamp(bpm)
    }

    // MARK: - Tempo control

    /// Set the tempo, clamped into the supported band. Re-anchors timing if running.
    func setBPM(_ value: Int) {
        let clamped = Tempo.clamp(value)
        guard clamped != bpm else { return }
        bpm = clamped
        if isRunning {
            // Re-anchor the next beat to keep the new tempo immediate without a stutter.
            nextBeat = Date().addingTimeInterval(interval)
        }
    }

    func nudge(_ delta: Int) { setBPM(bpm + delta) }

    /// Seconds between beats at the current tempo. `bpm` is bounded ≥ 20 so this is safe.
    private var interval: TimeInterval { 60.0 / Double(bpm) }

    // MARK: - Transport

    func start() {
        guard !isRunning else { return }
        isRunning = true
        beatCount = 0
        beatGenerator = Haptics.makeBeatGenerator()
        nextBeat = Date()  // fire the first beat right away
        let t = Timer(timeInterval: 0.01, repeats: true) { [weak self] _ in
            // Timer fires on the main run loop; hop to the main actor to touch state.
            Task { @MainActor [weak self] in self?.tick() }
        }
        t.tolerance = 0.005
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        beatGenerator = nil
        isRunning = false
    }

    func toggle() { isRunning ? stop() : start() }

    // MARK: - Beat emission

    private func tick() {
        let now = Date()
        // Emit any beats that have come due; the loop catches up if the run loop stalled.
        var emitted = 0
        while now >= nextBeat && emitted < 8 {
            emitBeat()
            nextBeat = nextBeat.addingTimeInterval(interval)
            emitted += 1
        }
        // If we fell far behind (e.g. backgrounded), snap forward to avoid a flurry.
        if now.timeIntervalSince(nextBeat) > interval {
            nextBeat = now.addingTimeInterval(interval)
        }
    }

    private func emitBeat() {
        beatToggle.toggle()
        beatCount += 1
        if hapticsEnabled { beatGenerator?.impactOccurred(intensity: 0.9) }
        if soundEnabled { AudioServicesPlaySystemSound(tickSoundID) }
    }

    // MARK: - Tap tempo

    /// Register a tap; once two-plus taps exist, set BPM to the averaged interval.
    /// Stale taps (older than 2.5s) reset the run so a fresh tempo isn't polluted.
    func tap() {
        let now = Date()
        if let last = taps.last, now.timeIntervalSince(last) > 2.5 {
            taps.removeAll()
        }
        taps.append(now)
        if taps.count > 6 { taps.removeFirst(taps.count - 6) }

        guard taps.count >= 2 else { return }
        var intervals: [TimeInterval] = []
        for i in 1..<taps.count {
            intervals.append(taps[i].timeIntervalSince(taps[i - 1]))
        }
        guard !intervals.isEmpty else { return }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        guard avg > 0 else { return }
        setBPM(Int((60.0 / avg).rounded()))
    }

    /// Clear tap history (e.g. when the practice screen disappears).
    func resetTaps() { taps.removeAll() }
}
