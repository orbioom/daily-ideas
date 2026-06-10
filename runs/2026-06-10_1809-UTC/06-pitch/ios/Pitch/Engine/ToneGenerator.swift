import Foundation
import AVFoundation

/// Synthesizes a sustained reference tone on-device (no audio files) using an
/// AVAudioSourceNode with a click-free gain ramp.
@Observable
final class ToneGenerator {
    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100

    private var phase: Double = 0
    private var frequency: Double = 440
    private var currentGain: Float = 0
    private var targetGain: Float = 0

    var isPlaying = false
    var playingFrequency: Double?
    var playingLabel: String?

    init() { setup() }

    private func setup() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let increment = self.frequency * twoPi / self.sampleRate
            for frame in 0..<Int(frameCount) {
                // Smooth the gain toward target to avoid clicks.
                if self.currentGain < self.targetGain {
                    self.currentGain = min(self.targetGain, self.currentGain + 0.0008)
                } else if self.currentGain > self.targetGain {
                    self.currentGain = max(self.targetGain, self.currentGain - 0.0008)
                }
                // A touch of second harmonic for warmth.
                let s = sin(self.phase) + 0.18 * sin(2 * self.phase)
                let value = Float(s) * self.currentGain * 0.5
                self.phase += increment
                if self.phase > twoPi { self.phase -= twoPi }
                for buffer in ablPointer {
                    guard let raw = buffer.mData else { continue }
                    let buf = raw.assumingMemoryBound(to: Float.self)
                    buf[frame] = value
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
    }

    func play(frequency: Double, label: String) {
        self.frequency = frequency
        targetGain = 1.0
        playingFrequency = frequency
        playingLabel = label
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        targetGain = 0
        isPlaying = false
        playingFrequency = nil
        playingLabel = nil
        // Let the ramp settle, then halt the engine.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.engine.stop()
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    func toggle(frequency: Double, label: String) {
        if isPlaying && playingFrequency == frequency { stop() }
        else { play(frequency: frequency, label: label) }
    }
}
