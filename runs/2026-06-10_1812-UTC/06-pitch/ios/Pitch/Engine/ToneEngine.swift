import Foundation
import AVFoundation

/// A small synth that produces a sustained reference tone (pitch pipe) and
/// short percussive clicks (metronome), generated in code with no audio files.
final class ToneEngine: ObservableObject {
    /// One shared synth for the whole app so the pitch pipe and metronome
    /// share a single audio graph.
    static let shared = ToneEngine()

    @Published private(set) var playingNote: String?

    private let engine = AVAudioEngine()
    private var srcNode: AVAudioSourceNode?
    private let sampleRate: Double = 44100
    private var started = false

    // Sustained tone state (read/written across threads; benign races only).
    private var toneFreq: Double = 440
    private var toneAmp: Double = 0
    private var toneTargetAmp: Double = 0
    private var tonePhase: Double = 0

    // Click transient state.
    private var clickPhase: Double = 0
    private var clickFreq: Double = 1000
    private var clickEnv: Double = 0
    private var clickDecay: Double = 0.9993

    init() { configure() }

    private func configure() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sr = self.sampleRate
            let twoPi = 2.0 * Double.pi
            for frame in 0..<Int(frameCount) {
                self.toneAmp += (self.toneTargetAmp - self.toneAmp) * 0.0006
                var sample = sin(self.tonePhase) * self.toneAmp
                self.tonePhase += twoPi * self.toneFreq / sr
                if self.tonePhase > twoPi { self.tonePhase -= twoPi }

                if self.clickEnv > 0.0005 {
                    sample += sin(self.clickPhase) * self.clickEnv * 0.6
                    self.clickPhase += twoPi * self.clickFreq / sr
                    if self.clickPhase > twoPi { self.clickPhase -= twoPi }
                    self.clickEnv *= self.clickDecay
                }

                let value = Float(max(-1, min(1, sample)))
                for buffer in ablPointer {
                    if let data = buffer.mData?.assumingMemoryBound(to: Float.self) {
                        data[frame] = value
                    }
                }
            }
            return noErr
        }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        srcNode = node
    }

    private func ensureRunning() {
        guard !started else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
        engine.prepare()
        do { try engine.start(); started = true } catch { started = false }
    }

    // MARK: - Pitch pipe

    func playTone(frequency: Double, note: String) {
        ensureRunning()
        toneFreq = frequency
        toneTargetAmp = 0.22
        DispatchQueue.main.async { self.playingNote = note }
    }

    func stopTone() {
        toneTargetAmp = 0
        DispatchQueue.main.async { self.playingNote = nil }
    }

    var isTonePlaying: Bool { toneTargetAmp > 0 }

    func toggleTone(frequency: Double, note: String) {
        if playingNote == note { stopTone() } else { playTone(frequency: frequency, note: note) }
    }

    // MARK: - Metronome click

    func click(accent: Bool) {
        ensureRunning()
        clickFreq = accent ? 1600 : 1000
        clickDecay = accent ? 0.9990 : 0.9993
        clickPhase = 0
        clickEnv = accent ? 1.0 : 0.7
    }

    func shutdown() {
        toneTargetAmp = 0
        clickEnv = 0
        if started { engine.stop(); started = false }
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
