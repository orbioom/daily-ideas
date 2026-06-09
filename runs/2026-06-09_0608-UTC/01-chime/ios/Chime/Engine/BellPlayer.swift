import AVFoundation

/// Synthesizes meditation bells on-device (no bundled audio files). Each tone is
/// a decaying sum of inharmonic partials rendered into a PCM buffer once, then
/// scheduled on a shared engine. Bells play through the .playback session so
/// they're audible even with the ring switch silenced.
final class BellPlayer {
    static let shared = BellPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var buffers: [BellTone: AVAudioPCMBuffer] = [:]
    private var started = false

    var enabled = true
    var volume: Float = 0.8

    private init() {
        engine.attach(player)
        if let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
    }

    private func startEngineIfNeeded() {
        guard !started else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            try engine.start()
            player.play()
            started = true
        } catch {
            started = false
        }
    }

    private func buffer(for tone: BellTone) -> AVAudioPCMBuffer? {
        if let cached = buffers[tone] { return cached }
        guard tone != .none, tone.frequency > 0 else { return nil }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        else { return nil }

        let decay = max(0.2, tone.decay)
        let frameCount = AVAudioFrameCount(sampleRate * decay)
        guard frameCount > 0,
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buf.floatChannelData?[0]
        else { return nil }
        buf.frameLength = frameCount

        let f0 = tone.frequency
        // Inharmonic partials give a metallic, bell-like timbre.
        let partials: [(mult: Double, amp: Double)] =
            [(1.0, 1.0), (2.0, 0.55), (2.76, 0.30), (5.4, 0.12)]
        let n = Int(frameCount)
        for i in 0..<n {
            let t = Double(i) / sampleRate
            let env = exp(-t / (decay * 0.34))
            let attack = min(1.0, t / 0.004)
            var sample = 0.0
            for p in partials {
                sample += p.amp * sin(2.0 * Double.pi * f0 * p.mult * t)
            }
            channel[i] = Float(sample * env * attack * 0.16)
        }
        buffers[tone] = buf
        return buf
    }

    /// Ring a tone. Safe to call rapidly; silent tones are ignored.
    func play(_ tone: BellTone) {
        guard enabled, tone != .none else { return }
        startEngineIfNeeded()
        guard started, let buf = buffer(for: tone) else { return }
        engine.mainMixerNode.outputVolume = max(0, min(volume, 1))
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buf, at: nil, options: [], completionHandler: nil)
    }

    /// Release the audio session when no sit is active.
    func deactivate() {
        guard started else { return }
        player.stop()
        engine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        started = false
    }
}
