import Foundation
import AVFoundation

/// Synthesizes a short, crisp clicker sound entirely on-device (no audio files)
/// using AVAudioEngine playing a tiny generated PCM buffer. Robust to setup failure:
/// if the engine can't start, sound is silently skipped and the caller still gets a haptic.
final class Clicker {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffer: AVAudioPCMBuffer?
    private var prepared = false

    init() {
        prepare()
    }

    private func prepare() {
        guard !prepared else { return }

        let sampleRate: Double = 44_100
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }

        // ~12ms click: a short decaying burst around 2.5kHz for a clean "tick".
        let durationSec = 0.012
        let frameCount = AVAudioFrameCount(sampleRate * durationSec)
        guard frameCount > 0,
              let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }
        buf.frameLength = frameCount

        if let channel = buf.floatChannelData?[0] {
            let n = Int(frameCount)
            let freq = 2_500.0
            for i in 0..<n {
                let t = Double(i) / sampleRate
                // Fast exponential decay envelope for a percussive click.
                let envelope = exp(-Double(i) / (Double(n) * 0.28))
                let sample = sin(2.0 * Double.pi * freq * t) * envelope
                channel[i] = Float(sample * 0.9)
            }
        }
        buffer = buf

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        prepared = true
    }

    /// Play a click. Configures a transient audio session that doesn't interrupt
    /// other audio. Fails silently if anything goes wrong.
    func click() {
        guard prepared, let buffer else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])

        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                return
            }
        }

        if !player.isPlaying {
            player.play()
        }
        player.scheduleBuffer(buffer, at: nil, options: [.interrupts], completionHandler: nil)
    }

    func stop() {
        if player.isPlaying { player.stop() }
        if engine.isRunning { engine.stop() }
    }
}
