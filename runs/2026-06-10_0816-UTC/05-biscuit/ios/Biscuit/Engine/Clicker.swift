import Foundation
import AVFoundation

/// A real clicker, synthesized on device — no audio files. Renders a short
/// two-transient "tick" into a PCM buffer and plays it through AVAudioEngine,
/// so it's crisp and latency-free for marker training.
@MainActor
final class Clicker {
    static let shared = Clicker()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private var started = false

    private init() {}

    private func prepare() {
        guard !started else { return }
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        buffer = Clicker.makeClick(format: format)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            player.play()
            started = true
        } catch {
            started = false
        }
    }

    func click() {
        prepare()
        guard started, let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    func stop() {
        guard started else { return }
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        started = false
    }

    /// Two sharp transients ~6 ms apart with a fast decay — the classic
    /// box-clicker timbre, built from filtered noise bursts.
    private static func makeClick(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100
        let frames = AVAudioFrameCount(sampleRate * 0.05)   // 50 ms
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames

        let channelCount = Int(format.channelCount)
        guard let channels = buffer.floatChannelData else { return nil }

        var seed: UInt64 = 0x9E3779B97F4A7C15
        func noise() -> Float {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Float(Int32(truncatingIfNeeded: seed >> 33)) / Float(Int32.max)
        }

        let onset1 = 0
        let onset2 = Int(sampleRate * 0.006)
        for i in 0..<Int(frames) {
            var sample: Float = 0
            // First transient
            let t1 = i - onset1
            if t1 >= 0 {
                let env = expf(-Float(t1) / (Float(sampleRate) * 0.0018))
                sample += noise() * env * 0.9
            }
            // Second, quieter transient
            let t2 = i - onset2
            if t2 >= 0 {
                let env = expf(-Float(t2) / (Float(sampleRate) * 0.0014))
                sample += noise() * env * 0.5
            }
            sample = max(-1, min(1, sample))
            for c in 0..<channelCount {
                channels[c][i] = sample
            }
        }
        return buffer
    }
}
