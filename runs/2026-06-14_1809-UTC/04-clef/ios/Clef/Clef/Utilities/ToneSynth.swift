import AVFoundation

/// A tiny sine-tone player for sounding the answered note. Enveloped to avoid clicks.
/// Fully guarded — if the audio engine cannot start, playback is silently skipped.
/// All shared tone state is protected by `lock`, so the render block (audio thread)
/// and the calling thread never race.
final class ToneSynth: @unchecked Sendable {
    static let shared = ToneSynth()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100
    private var started = false

    // Tone state, read on the audio thread.
    private var phase: Double = 0
    private var phaseIncrement: Double = 0
    private var remainingSamples: Int = 0
    private var totalSamples: Int = 1
    private let lock = NSLock()

    private init() {}

    /// Start the engine lazily. Returns true if running.
    @discardableResult
    private func startIfNeeded() -> Bool {
        if started { return true }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return false
        }
        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            self.lock.lock()
            var ph = self.phase
            let inc = self.phaseIncrement
            var remaining = self.remainingSamples
            let total = max(1, self.totalSamples)
            self.lock.unlock()

            for frame in 0..<Int(frameCount) {
                var sample: Float = 0
                if remaining > 0 {
                    // Simple attack/release envelope to avoid clicks.
                    let elapsed = total - remaining
                    let attack = min(total / 8, 1200)
                    let release = min(total / 3, 6000)
                    var env: Double = 1
                    if elapsed < attack {
                        env = Double(elapsed) / Double(max(1, attack))
                    } else if remaining < release {
                        env = Double(remaining) / Double(max(1, release))
                    }
                    sample = Float(sin(ph) * env * 0.22)
                    ph += inc
                    if ph > 2 * .pi { ph -= 2 * .pi }
                    remaining -= 1
                }
                for buffer in ablPointer {
                    if let data = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        data[frame] = sample
                    }
                }
            }

            self.lock.lock()
            self.phase = ph
            self.remainingSamples = remaining
            self.lock.unlock()
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            started = true
            return true
        } catch {
            started = false
            return false
        }
    }

    /// Play the given MIDI note for a short duration.
    func play(midi: Int, durationMs: Double = 450) {
        guard startIfNeeded() else { return }
        let freq = 440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
        guard freq > 0, freq.isFinite else { return }
        let samples = max(1, Int(sampleRate * durationMs / 1000))
        lock.lock()
        phase = 0
        phaseIncrement = 2 * .pi * freq / sampleRate
        totalSamples = samples
        remainingSamples = samples
        lock.unlock()
    }
}
