import Foundation
import AVFoundation

/// Synthesizes alarm tones entirely in code via `AVAudioEngine` — no audio files. Each tone
/// is rendered into a looping PCM buffer and played through a player node, with a volume ramp
/// (gradual fade-in) applied on the mixer. Loops until `stop()` is called.
///
/// Honest note: while the app is OPEN or BACKGROUNDED (audio background mode), this plays
/// reliably. If the app is force-quit, iOS will not let a third-party app force audio; the
/// scheduled local notification is the backstop. The engine never throws on the user path —
/// every failure degrades to silence rather than crashing.
@MainActor
final class RingEngine: ObservableObject {

    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let mixer: AVAudioMixerNode
    private let sampleRate: Double = 44_100
    private var rampTask: Task<Void, Never>?
    private var didAttach = false

    // Live preview uses a shorter ramp and auto-stops after a few seconds.
    private var previewTimer: Timer?

    init() {
        mixer = engine.mainMixerNode
    }

    // MARK: Session

    /// Configure the shared audio session for playback that mixes with the ring. Safe to call
    /// repeatedly. Never throws to the caller.
    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            // Degrade silently — the notification backstop still fires.
        }
    }

    private func deactivateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    // MARK: Public control

    /// Start ringing the given sound, ramping volume from ~0 to full over `rampSeconds`.
    /// Loops until `stop()`. If `preview` is true, auto-stops after a short window.
    func start(soundName: String, rampSeconds: Int, preview: Bool = false) {
        stop()
        activateSession()

        guard let buffer = makeBuffer(for: soundName) else { return }

        attachIfNeeded()

        do {
            try engine.start()
        } catch {
            return
        }

        let ramp = max(0, min(120, rampSeconds))
        // Start quiet, then ramp up. Preview always ramps quickly so it's audible immediately.
        mixer.outputVolume = (preview || ramp == 0) ? 0.85 : 0.04

        player.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        player.play()
        isPlaying = true

        if preview {
            previewTimer?.invalidate()
            previewTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.stop() }
            }
        } else if ramp > 0 {
            startRamp(seconds: ramp)
        }
    }

    /// Stop ringing and release the session.
    func stop() {
        rampTask?.cancel()
        rampTask = nil
        previewTimer?.invalidate()
        previewTimer = nil
        if player.isPlaying { player.stop() }
        if engine.isRunning { engine.stop() }
        isPlaying = false
        deactivateSession()
    }

    /// Briefly preview a sound (used by the sound picker). Auto-stops.
    func preview(soundName: String) {
        start(soundName: soundName, rampSeconds: 0, preview: true)
    }

    // MARK: Engine wiring

    private func attachIfNeeded() {
        guard !didAttach else { return }
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        engine.connect(player, to: mixer, format: format)
        didAttach = true
    }

    private func startRamp(seconds: Int) {
        rampTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let steps = 40
            let target: Float = 0.85
            let start: Float = self.mixer.outputVolume
            let stepDuration = UInt64((Double(seconds) / Double(steps)) * 1_000_000_000)
            for i in 1...steps {
                if Task.isCancelled { return }
                let t = Float(i) / Float(steps)
                // Ease-in curve so the rise feels gentle then assertive.
                let eased = t * t
                self.mixer.outputVolume = start + (target - start) * eased
                try? await Task.sleep(nanoseconds: max(1_000_000, stepDuration))
            }
            self.mixer.outputVolume = target
        }
    }

    // MARK: Tone synthesis

    /// Build a looping mono PCM buffer for the named sound. Returns nil on allocation failure.
    private func makeBuffer(for soundName: String) -> AVAudioPCMBuffer? {
        let samples = renderSamples(for: soundName)
        guard !samples.isEmpty,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(samples.count)),
              let channel = buffer.floatChannelData else { return nil }
        buffer.frameLength = AVAudioFrameCount(samples.count)
        for i in 0..<samples.count {
            channel[0][i] = samples[i]
        }
        return buffer
    }

    /// Produce one loopable cycle of float samples for the named tone.
    private func renderSamples(for soundName: String) -> [Float] {
        switch soundName {
        case "beep":     return renderBeep()
        case "marimba":  return renderMarimba()
        case "birdsong": return renderBirdsong()
        case "sunrise":  return renderSunrise()
        case "pulse":    return renderPulse()
        default:         return renderChime()
        }
    }

    private func frames(_ seconds: Double) -> Int { max(1, Int(seconds * sampleRate)) }

    /// Gentle ascending arpeggio (A-C#-E-A), each note with a soft pluck envelope, then a rest.
    private func renderChime() -> [Float] {
        let notes: [Double] = [440.0, 554.37, 659.25, 880.0]
        let noteDur = 0.34
        let restDur = 0.5
        var out: [Float] = []
        out.reserveCapacity(frames(Double(notes.count) * noteDur + restDur))
        for freq in notes {
            let n = frames(noteDur)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let env = envADSR(i: i, total: n, attack: 0.01, release: 0.18)
                // Add a soft octave overtone for sparkle.
                let s = sin(2 * .pi * freq * t) * 0.8 + sin(2 * .pi * freq * 2 * t) * 0.18
                out.append(Float(s * env * 0.5))
            }
        }
        appendSilence(&out, seconds: restDur)
        return out
    }

    /// Classic square-wave beep: 0.2s on, 0.2s off, twice, then a longer rest.
    private func renderBeep() -> [Float] {
        let freq = 880.0
        var out: [Float] = []
        for _ in 0..<2 {
            let n = frames(0.22)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let raw = sin(2 * .pi * freq * t)
                let sq = raw >= 0 ? 1.0 : -1.0
                let env = envADSR(i: i, total: n, attack: 0.004, release: 0.02)
                out.append(Float(sq * env * 0.32))
            }
            appendSilence(&out, seconds: 0.18)
        }
        appendSilence(&out, seconds: 0.5)
        return out
    }

    /// Warm marimba pulse: a quick bar-like tone with strong fundamental + a 4th partial,
    /// fast decay, repeated as a gentle two-note motif.
    private func renderMarimba() -> [Float] {
        let notes: [Double] = [392.0, 523.25]
        var out: [Float] = []
        for freq in notes {
            let n = frames(0.4)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let env = exp(-7.0 * t)  // fast wooden decay
                let s = sin(2 * .pi * freq * t) * 0.9
                      + sin(2 * .pi * freq * 4 * t) * 0.25
                out.append(Float(s * env * 0.5))
            }
            appendSilence(&out, seconds: 0.12)
        }
        appendSilence(&out, seconds: 0.45)
        return out
    }

    /// Soft birdsong: filtered noise chirps whose pitch sweeps, over a quiet dawn drone.
    private func renderBirdsong() -> [Float] {
        var rng = SplitMix64(seed: 0xB12D5001)
        let total = frames(2.2)
        var out = [Float](repeating: 0, count: total)
        // Low drone underneath.
        for i in 0..<total {
            let t = Double(i) / sampleRate
            out[i] += Float(sin(2 * .pi * 196.0 * t) * 0.05)
        }
        // Three chirps with frequency sweeps.
        let chirps: [(start: Double, dur: Double, f0: Double, f1: Double)] = [
            (0.15, 0.18, 1800, 2600),
            (0.7, 0.22, 2200, 1500),
            (1.4, 0.2, 2000, 2900)
        ]
        for chirp in chirps {
            let startIdx = frames(chirp.start)
            let n = frames(chirp.dur)
            var phase = 0.0
            for j in 0..<n {
                let idx = startIdx + j
                guard idx < total else { break }
                let frac = Double(j) / Double(n)
                let freq = chirp.f0 + (chirp.f1 - chirp.f0) * frac
                phase += 2 * .pi * freq / sampleRate
                let env = sin(.pi * frac)  // smooth in/out
                let noise = (Double(rng.int(2000)) / 1000.0 - 1.0) * 0.15
                let tone = sin(phase) * 0.6 + noise
                out[idx] += Float(tone * env * 0.35)
            }
        }
        return out
    }

    /// Sunrise bells: layered inharmonic bell partials that bloom and shimmer.
    private func renderSunrise() -> [Float] {
        let fundamental = 523.25
        let partials: [(ratio: Double, gain: Double)] = [
            (1.0, 0.5), (2.0, 0.3), (2.76, 0.2), (3.96, 0.12), (5.4, 0.08)
        ]
        let n = frames(1.8)
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / sampleRate
            var s = 0.0
            for p in partials {
                let decay = exp(-1.6 * t / p.gain.squareRootSafe())
                s += sin(2 * .pi * fundamental * p.ratio * t) * p.gain * decay
            }
            // Slow shimmer LFO.
            let shimmer = 1.0 + 0.08 * sin(2 * .pi * 5.5 * t)
            out[i] = Float(s * shimmer * 0.4)
        }
        appendSilence(&out, seconds: 0.4)
        return out
    }

    /// Heartbeat pulse: two low thumps (lub-dub) then a rest.
    private func renderPulse() -> [Float] {
        var out: [Float] = []
        let beats: [(freq: Double, dur: Double, gap: Double, gain: Double)] = [
            (90, 0.16, 0.12, 0.6),
            (70, 0.2, 0.55, 0.5)
        ]
        for beat in beats {
            let n = frames(beat.dur)
            for i in 0..<n {
                let t = Double(i) / sampleRate
                let env = exp(-9.0 * t)
                let s = sin(2 * .pi * beat.freq * t)
                out.append(Float(s * env * beat.gain))
            }
            appendSilence(&out, seconds: beat.gap)
        }
        return out
    }

    // MARK: Envelope helpers

    /// Linear attack / release envelope over a buffer of `total` samples.
    private func envADSR(i: Int, total: Int, attack: Double, release: Double) -> Double {
        guard total > 0 else { return 0 }
        let t = Double(i) / sampleRate
        let dur = Double(total) / sampleRate
        let releaseStart = max(0, dur - release)
        if t < attack {
            return attack > 0 ? t / attack : 1
        } else if t > releaseStart {
            let rt = dur - t
            return release > 0 ? max(0, rt / release) : 0
        }
        return 1
    }

    private func appendSilence(_ out: inout [Float], seconds: Double) {
        out.append(contentsOf: [Float](repeating: 0, count: frames(seconds)))
    }
}

private extension Double {
    /// Square root that never returns NaN for tiny/zero inputs (used in bell decay scaling).
    func squareRootSafe() -> Double {
        self > 0 ? Foundation.sqrt(self) : 0.0001
    }
}
