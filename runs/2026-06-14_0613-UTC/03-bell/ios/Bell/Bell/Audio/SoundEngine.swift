import Foundation
import AVFoundation

/// In-code audio synthesis with AVAudioEngine. Every setup path is wrapped in
/// do/catch and every optional is guarded — if anything fails, `isAvailable`
/// stays false and the timer runs silently (callers fire a haptic cue instead).
final class SoundEngine {
    private let engine = AVAudioEngine()
    private let bellPlayer = AVAudioPlayerNode()
    private let ambientPlayer = AVAudioPlayerNode()

    private let sampleRate: Double = 44_100
    private var format: AVAudioFormat?

    /// True only when the full audio graph started successfully.
    private(set) var isAvailable = false
    private var didConfigureSession = false

    // MARK: - Lifecycle

    /// Build & start the graph. Returns false (silent mode) on any failure.
    @discardableResult
    func start() -> Bool {
        guard !isAvailable else { return true }

        // Audio session — mix with others so it never hijacks playback.
        if !didConfigureSession {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, options: [.mixWithOthers])
                try session.setActive(true)
                didConfigureSession = true
            } catch {
                isAvailable = false
                return false
            }
        }

        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            isAvailable = false
            return false
        }
        format = fmt

        engine.attach(bellPlayer)
        engine.attach(ambientPlayer)
        engine.connect(bellPlayer, to: engine.mainMixerNode, format: fmt)
        engine.connect(ambientPlayer, to: engine.mainMixerNode, format: fmt)

        do {
            try engine.start()
            bellPlayer.play()
            ambientPlayer.play()
            isAvailable = true
            return true
        } catch {
            isAvailable = false
            return false
        }
    }

    func stop() {
        ambientPlayer.stop()
        bellPlayer.stop()
        if engine.isRunning { engine.stop() }
        if didConfigureSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            didConfigureSession = false
        }
        isAvailable = false
    }

    // MARK: - Bell

    /// Ring a bell. No-op (returns false) if audio is unavailable.
    @discardableResult
    func ringBell(_ tone: BellTone, volume: Float = 0.9) -> Bool {
        guard isAvailable, let fmt = format,
              let buffer = makeBellBuffer(tone, format: fmt) else { return false }
        bellPlayer.volume = volume
        bellPlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        return true
    }

    private func makeBellBuffer(_ tone: BellTone, format fmt: AVAudioFormat) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(tone.duration * sampleRate)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else { return nil }

        let partials = tone.partials
        let n = Int(frames)
        let attack = 0.006 // brief strike onset
        for i in 0..<n {
            let t = Double(i) / sampleRate
            var sample = 0.0
            for p in partials {
                sample += p.amp * sin(2.0 * Double.pi * p.freq * t) * exp(-t * p.decay)
            }
            // Soft onset envelope to avoid a click.
            let onset = t < attack ? (t / attack) : 1.0
            sample *= onset
            channel[i] = Float(sample * 0.32)
        }
        buffer.frameLength = frames
        return buffer
    }

    // MARK: - Ambient

    /// Loop a soundscape at low volume. No-op if unavailable or `.none`.
    @discardableResult
    func startAmbient(_ ambient: Ambient, volume: Float = 0.16) -> Bool {
        guard isAvailable, ambient != .none, let fmt = format,
              let buffer = makeAmbientBuffer(ambient, format: fmt) else { return false }
        ambientPlayer.stop()
        ambientPlayer.volume = volume
        ambientPlayer.scheduleBuffer(buffer, at: nil, options: [.loops], completionHandler: nil)
        ambientPlayer.play()
        return true
    }

    func stopAmbient() {
        guard isAvailable else { return }
        ambientPlayer.stop()
    }

    /// Quick volume fade-out for the ambient bed.
    func fadeAmbient(to target: Float = 0, over seconds: Double = 1.5) {
        guard isAvailable else { return }
        let steps = 20
        let start = ambientPlayer.volume
        let delta = (target - start) / Float(steps)
        for s in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds * Double(s) / Double(steps)) { [weak self] in
                guard let self else { return }
                self.ambientPlayer.volume = start + delta * Float(s)
                if s == steps && target <= 0 { self.ambientPlayer.stop() }
            }
        }
    }

    /// A ~4s seamless-ish loop buffer per ambient type.
    private func makeAmbientBuffer(_ ambient: Ambient, format fmt: AVAudioFormat) -> AVAudioPCMBuffer? {
        let loopSeconds = 4.0
        let frames = AVAudioFrameCount(loopSeconds * sampleRate)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else { return nil }

        let n = Int(frames)
        var lastBrown: Double = 0
        var seed: UInt64 = 0x9E3779B97F4A7C15

        func nextNoise() -> Double {
            // xorshift white noise in [-1, 1]
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17
            return (Double(seed % 20001) / 10000.0) - 1.0
        }

        for i in 0..<n {
            let t = Double(i) / sampleRate
            var sample = 0.0
            switch ambient {
            case .none:
                sample = 0
            case .brownNoise:
                let white = nextNoise()
                lastBrown = (lastBrown + 0.02 * white) / 1.02
                sample = lastBrown * 3.2
            case .rain:
                let white = nextNoise()
                lastBrown = (lastBrown + 0.04 * white) / 1.04
                // higher-passed hiss + gentle filtered bed
                sample = (white * 0.35 + lastBrown * 1.6)
            case .drone:
                sample = 0.5 * sin(2 * .pi * 110 * t)
                    + 0.3 * sin(2 * .pi * 164.81 * t)
                    + 0.2 * sin(2 * .pi * 220 * t)
                // slow LFO shimmer
                sample *= 0.7 + 0.3 * sin(2 * .pi * 0.1 * t)
            case .ocean:
                let white = nextNoise()
                lastBrown = (lastBrown + 0.03 * white) / 1.03
                // swell LFO ~0.12 Hz
                let swell = 0.5 + 0.5 * sin(2 * .pi * 0.12 * t)
                sample = lastBrown * 2.6 * swell
            }
            // Cross-fade the loop edges to reduce the seam click.
            let edge = 0.08 * loopSeconds
            var gain = 1.0
            if t < edge { gain = t / edge }
            else if t > loopSeconds - edge { gain = (loopSeconds - t) / edge }
            channel[i] = Float(max(-1, min(1, sample)) * gain * 0.9)
        }
        buffer.frameLength = frames
        return buffer
    }
}
