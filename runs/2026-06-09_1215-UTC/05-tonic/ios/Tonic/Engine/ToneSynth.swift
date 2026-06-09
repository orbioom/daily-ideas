import AVFoundation

/// How a set of notes is voiced: spelled out low-to-high, high-to-low, or sounded together.
enum PlayStyle {
    case sequenceAscending
    case sequenceDescending
    case simultaneous
}

/// Two synthesized timbres. Triangle is approximated by summing odd harmonics so
/// it stays soft and band-limited rather than a buzzy ideal triangle.
enum Waveform: String, CaseIterable, Identifiable, Codable {
    case sine, triangle
    var id: String { rawValue }
    var label: String {
        switch self {
        case .sine: return "Sine"
        case .triangle: return "Triangle"
        }
    }
}

/// Synthesizes ear-training tones on-device — no bundled audio files. Every
/// note is rendered into a PCM float buffer with a short attack/release envelope
/// (so there are no clicks) and scheduled on a shared AVAudioEngine. The whole
/// thing degrades to a calm no-op if audio is unavailable; it never crashes.
final class ToneSynth {
    static let shared = ToneSynth()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var started = false
    /// Set if a start attempt failed, so the UI can show a calm error.
    private(set) var startFailed = false

    // Driven by Settings.
    var enabled = true
    var volume: Float = 0.8
    var noteDurationSec: Double = 0.6
    var waveformRaw: String = Waveform.sine.rawValue

    private var waveform: Waveform { Waveform(rawValue: waveformRaw) ?? .sine }

    private init() {
        engine.attach(player)
        if let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }

    /// True once audio is running, or before any start has been attempted.
    /// Flips to false only after a start attempt fails, so the UI can show a
    /// calm error rather than guessing.
    var isAvailable: Bool { started || !startFailed }

    @discardableResult
    private func startEngineIfNeeded() -> Bool {
        guard !started else { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            player.play()
            started = true
            startFailed = false
        } catch {
            started = false
            startFailed = true
        }
        return started
    }

    /// One waveform sample at phase `theta` (radians).
    private func sample(_ theta: Double) -> Double {
        switch waveform {
        case .sine:
            return sin(theta)
        case .triangle:
            // Soft triangle: fundamental plus a couple of odd harmonics with
            // alternating sign and 1/n^2 falloff. Stays mellow, not buzzy.
            let h1 = sin(theta)
            let h3 = sin(3 * theta) / 9.0
            let h5 = sin(5 * theta) / 25.0
            return (h1 - h3 + h5) * 0.92
        }
    }

    /// Render one note's worth of samples into `channel` starting at `offset`.
    /// Returns the number of frames written.
    private func renderNote(frequency: Double,
                            into channel: UnsafeMutablePointer<Float>,
                            offset: Int,
                            frames: Int,
                            gain: Double) {
        guard frequency > 0, frames > 0 else { return }
        let attack = min(0.012, Double(frames) / sampleRate * 0.2)
        let release = min(0.05, Double(frames) / sampleRate * 0.35)
        let totalSec = Double(frames) / sampleRate
        let twoPiF = 2.0 * Double.pi * frequency
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            // Trapezoidal attack/release envelope to avoid clicks.
            var env = 1.0
            if t < attack { env = t / attack }
            else if t > totalSec - release { env = max(0, (totalSec - t) / release) }
            let value = sample(twoPiF * t) * env * gain
            channel[offset + i] += Float(value)
        }
    }

    /// Play a set of frequencies in the given style. Safe to call repeatedly.
    /// No-ops (rather than crashing) if audio cannot start or buffers can't be made.
    func playFrequencies(_ freqs: [Double], style: PlayStyle) {
        let valid = freqs.filter { $0 > 0 }
        guard enabled, !valid.isEmpty, startEngineIfNeeded() else { return }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        let noteFrames = max(1, Int(sampleRate * max(0.1, noteDurationSec)))
        let ordered: [Double]
        switch style {
        case .sequenceAscending: ordered = valid
        case .sequenceDescending: ordered = Array(valid.reversed())
        case .simultaneous: ordered = valid
        }

        let totalFrames: Int
        switch style {
        case .simultaneous: totalFrames = noteFrames
        default: totalFrames = noteFrames * ordered.count
        }
        guard totalFrames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(totalFrames)),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = AVAudioFrameCount(totalFrames)

        // Zero the buffer before summing into it.
        for i in 0..<totalFrames { channel[i] = 0 }

        switch style {
        case .simultaneous:
            // Sum notes; scale gain down so a stacked chord doesn't clip.
            let gain = 0.20 / Double(max(1, ordered.count)).squareRoot()
            for f in ordered {
                renderNote(frequency: f, into: channel, offset: 0,
                           frames: noteFrames, gain: gain)
            }
        default:
            for (idx, f) in ordered.enumerated() {
                renderNote(frequency: f, into: channel,
                           offset: idx * noteFrames, frames: noteFrames, gain: 0.20)
            }
        }

        engine.mainMixerNode.outputVolume = max(0, min(volume, 1))
        // Replace any in-flight playback so a Replay starts cleanly.
        player.stop()
        player.play()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    /// Estimated playback length so the UI can gate its loading state.
    func estimatedDuration(noteCount: Int, style: PlayStyle) -> Double {
        let d = max(0.1, noteDurationSec)
        switch style {
        case .simultaneous: return d
        default: return d * Double(max(1, noteCount))
        }
    }

    /// Preview a single pitch (used by Settings).
    func previewTone() {
        playFrequencies([Theory.frequency(forMidi: 69)], style: .simultaneous)
    }
}
