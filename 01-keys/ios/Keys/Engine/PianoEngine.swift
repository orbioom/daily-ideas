import AVFoundation
import Foundation

@MainActor
@Observable
final class PianoEngine {
    private var audioEngine = AVAudioEngine()
    private var mixer = AVAudioMixerNode()
    private var activeNodes: [Int: AVAudioSourceNode] = [:]
    private var releasePhases: [Int: Double] = [:]
    private var isConfigured = false

    func configure() {
        guard !isConfigured else { return }
        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            isConfigured = true
        } catch {
            // Audio session failed to start — app still usable without sound
        }
    }

    func playNote(_ midi: Int, velocity: Float = 0.7) {
        configure()
        guard isConfigured else { return }

        // Stop previous instance of same note
        stopNote(midi)

        let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        var phase = 0.0
        var elapsed = 0.0
        var inRelease = false
        var releaseStart = 0.0
        let sr = 44100.0
        let attackTime = 0.010
        let decayTime = 0.15
        let sustainLevel = 0.6
        let releaseTime = 0.4
        let vel = Double(velocity)

        let format = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 2)

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                elapsed += 1.0 / sr

                // Check release flag
                if let releaseStart_ = self?.releasePhases[midi], !inRelease {
                    inRelease = true
                    releaseStart = elapsed
                    _ = releaseStart_
                }

                let env: Double
                if inRelease {
                    let relElapsed = elapsed - releaseStart
                    let relFrac = min(relElapsed / releaseTime, 1.0)
                    env = sustainLevel * (1.0 - relFrac) * vel
                } else if elapsed < attackTime {
                    env = (elapsed / attackTime) * vel
                } else if elapsed < attackTime + decayTime {
                    let decayFrac = (elapsed - attackTime) / decayTime
                    env = (1.0 - (1.0 - sustainLevel) * decayFrac) * vel
                } else {
                    env = sustainLevel * vel
                }

                // Additive synthesis: fundamental + 2nd + 3rd + 4th harmonics
                let sample = (sin(2.0 * .pi * phase) * 0.6
                            + sin(4.0 * .pi * phase) * 0.25
                            + sin(6.0 * .pi * phase) * 0.10
                            + sin(8.0 * .pi * phase) * 0.05) * env * 0.3

                phase += freq / sr
                if phase > 1.0 { phase -= 1.0 }

                let floatSample = Float(sample)
                for buffer in ablPointer {
                    guard let mData = buffer.mData else { continue }
                    let buf = mData.assumingMemoryBound(to: Float.self)
                    buf[frame] = floatSample
                }
            }
            return noErr
        }

        audioEngine.attach(node)
        audioEngine.connect(node, to: mixer, format: format)
        activeNodes[midi] = node

        // Auto-release after 2 seconds
        let midiCopy = midi
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.releasePhases[midiCopy] = 0.0
            try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
            self.cleanupNote(midiCopy)
        }
    }

    func stopNote(_ midi: Int) {
        releasePhases[midi] = 0.0
        let releaseTime = 0.4
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(releaseTime * 1_000_000_000))
            self.cleanupNote(midi)
        }
    }

    private func cleanupNote(_ midi: Int) {
        guard let node = activeNodes[midi] else { return }
        audioEngine.detach(node)
        activeNodes.removeValue(forKey: midi)
        releasePhases.removeValue(forKey: midi)
    }

    static func noteToFreq(_ midi: Int) -> Float {
        440.0 * pow(2.0, Float(midi - 69) / 12.0)
    }

    static func noteName(_ midi: Int) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let octave = (midi / 12) - 1
        return "\(names[midi % 12])\(octave)"
    }

    static func isBlackKey(_ midi: Int) -> Bool {
        let mod = midi % 12
        return [1, 3, 6, 8, 10].contains(mod)
    }
}
