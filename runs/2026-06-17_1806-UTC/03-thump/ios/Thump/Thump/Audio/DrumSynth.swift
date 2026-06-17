import AVFoundation
import Foundation

/// Pure-DSP drum synthesizer. Renders each voice ONCE into an
/// `AVAudioPCMBuffer` (mono, float32, 44.1 kHz) using parameterized math —
/// there are no audio files anywhere in Thump.
struct DrumSynth {
    static let sampleRate: Double = 44_100

    /// A small, deterministic linear-congruential RNG so noise is identical
    /// across runs (fixed seed → reproducible timbres, no `arc4random`).
    private struct FixedRNG {
        var state: UInt64
        init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
        mutating func nextUnit() -> Double {
            // xorshift64* — returns a value in -1...1
            state ^= state >> 12
            state ^= state << 25
            state ^= state >> 27
            let v = (state &* 0x2545F4914F6CDD1D) >> 11
            return (Double(v) / Double(1 << 53)) * 2.0 - 1.0
        }
    }

    /// Build a buffer for one voice using the kit's parameters. Returns `nil`
    /// if the audio format can't be created or the computed length is empty.
    static func makeBuffer(voice: DrumVoice, params: VoiceParams, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let length = voiceDuration(voice: voice, params: params)
        let frameCount = AVAudioFrameCount(max(1, Int(length * sampleRate)))
        guard frameCount > 0 else { return nil }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        guard let channel = buffer.floatChannelData?[0] else { return nil }

        var rng = FixedRNG(seed: UInt64(voice.rawValue + 1) &* 0xABCD1234)
        let n = Int(frameCount)
        let sr = sampleRate

        switch voice {
        case .kick, .tom:
            renderPitchedTone(channel, n: n, sr: sr, params: params)
        case .snare:
            renderSnare(channel, n: n, sr: sr, params: params, rng: &rng)
        case .closedHat, .openHat:
            renderHat(channel, n: n, sr: sr, params: params, rng: &rng)
        case .clap:
            renderClap(channel, n: n, sr: sr, params: params, rng: &rng)
        case .rim:
            renderRim(channel, n: n, sr: sr, params: params, rng: &rng)
        case .cowbell:
            renderCowbell(channel, n: n, sr: sr, params: params)
        }
        return buffer
    }

    /// Total buffer length per voice (decay + a little tail), capped for safety.
    private static func voiceDuration(voice: DrumVoice, params: VoiceParams) -> Double {
        let base = params.decay * 4.0 + 0.02
        return min(max(base, 0.03), 1.5)
    }

    // MARK: - Renderers

    /// Kick / Tom: sine with a downward pitch envelope × exponential amp decay.
    private static func renderPitchedTone(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams) {
        var phase = 0.0
        let pitchTau = max(params.decay * 0.4, 0.001)
        for i in 0..<n {
            let t = Double(i) / sr
            let freq = params.endFreq + (params.startFreq - params.endFreq) * exp(-t / pitchTau)
            phase += 2.0 * .pi * freq / sr
            let env = exp(-t / max(params.decay, 0.001))
            var s = sin(phase) * env
            // Slight click transient at the very start for punch.
            if i < 4 { s += (1.0 - Double(i) / 4.0) * 0.25 }
            out[i] = clamp(s * params.gain)
        }
    }

    /// Snare: a short tone + a white-noise burst, both exponential decay.
    private static func renderSnare(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams, rng: inout FixedRNG) {
        var phase = 0.0
        let toneTau = max(params.decay * 0.6, 0.001)
        let noiseTau = max(params.decay, 0.001)
        var prevNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            phase += 2.0 * .pi * params.startFreq / sr
            let tone = sin(phase) * exp(-t / toneTau) * (1.0 - params.noiseMix)
            let raw = rng.nextUnit()
            let noise = brightNoise(raw, prev: &prevNoise, brightness: params.brightness) * exp(-t / noiseTau) * params.noiseMix
            out[i] = clamp((tone + noise) * params.gain)
        }
    }

    /// Hats: bright (high-passed) white noise, short or longer decay.
    private static func renderHat(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams, rng: inout FixedRNG) {
        let tau = max(params.decay, 0.001)
        var prevNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            let raw = rng.nextUnit()
            let noise = brightNoise(raw, prev: &prevNoise, brightness: params.brightness)
            out[i] = clamp(noise * exp(-t / tau) * params.gain)
        }
    }

    /// Clap: several noise bursts in quick succession then a decaying tail.
    private static func renderClap(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams, rng: inout FixedRNG) {
        let burstOffsets = [0.0, 0.008, 0.016, 0.024]   // seconds
        let burstTau = 0.012
        let tailTau = max(params.decay, 0.001)
        var prevNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            var env = 0.0
            for off in burstOffsets where t >= off {
                env += exp(-(t - off) / burstTau)
            }
            // Add a softer decaying tail after the final burst.
            if let last = burstOffsets.last, t >= last {
                env += 0.4 * exp(-(t - last) / tailTau)
            }
            let raw = rng.nextUnit()
            let noise = brightNoise(raw, prev: &prevNoise, brightness: params.brightness)
            out[i] = clamp(noise * min(env, 1.0) * params.gain)
        }
    }

    /// Rim: a very short bright click — tiny tone + noise.
    private static func renderRim(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams, rng: inout FixedRNG) {
        var phase = 0.0
        let tau = max(params.decay, 0.001)
        var prevNoise = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            phase += 2.0 * .pi * params.startFreq / sr
            let tone = sin(phase) * (1.0 - params.noiseMix)
            let raw = rng.nextUnit()
            let noise = brightNoise(raw, prev: &prevNoise, brightness: params.brightness) * params.noiseMix
            out[i] = clamp((tone + noise) * exp(-t / tau) * params.gain)
        }
    }

    /// Cowbell: two summed sine partials, short decay.
    private static func renderCowbell(_ out: UnsafeMutablePointer<Float>, n: Int, sr: Double, params: VoiceParams) {
        var p1 = 0.0, p2 = 0.0
        let f1 = params.startFreq
        let f2 = params.startFreq * (800.0 / 540.0)   // ~540 + ~800 partials
        let tau = max(params.decay, 0.001)
        for i in 0..<n {
            let t = Double(i) / sr
            p1 += 2.0 * .pi * f1 / sr
            p2 += 2.0 * .pi * f2 / sr
            let s = (sin(p1) + 0.8 * sin(p2)) * 0.5 * exp(-t / tau)
            out[i] = clamp(s * params.gain)
        }
    }

    // MARK: - Helpers

    /// Simple one-pole high-pass emphasis to brighten noise. `brightness`
    /// 0 keeps it dull (low-pass-ish), 1 makes it crisp (high-pass-ish).
    private static func brightNoise(_ raw: Double, prev: inout Double, brightness: Double) -> Double {
        let hp = raw - prev * (1.0 - brightness)
        prev = raw
        // Mix raw and high-passed by brightness.
        return raw * (1.0 - brightness) + hp * brightness
    }

    private static func clamp(_ v: Double) -> Float {
        Float(min(1.0, max(-1.0, v)))
    }
}
