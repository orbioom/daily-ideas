import Foundation
import AVFAudio
import Observation

/// Holds the oscillator state touched by the real-time render thread, isolated
/// from the main actor. Reads/writes of these primitive Doubles are simple
/// scalar stores; the amplitude is ramped on the render thread so retunes and
/// start/stop don't click.
final class ToneRenderState: @unchecked Sendable {
    let sampleRate: Double
    var phase: Double = 0
    var targetFrequency: Double = 440
    var currentAmplitude: Double = 0
    var targetAmplitude: Double = 0

    init(sampleRate: Double) { self.sampleRate = sampleRate }
}

/// Reference-pitch generator (a pitch pipe). Plays a sustained sine tone for a
/// chosen note via an `AVAudioSourceNode`, computing samples on the render
/// thread with a continuous phase accumulator (no clicks, no audio files).
@MainActor
@Observable
final class ToneGenerator {

    private(set) var isPlaying = false
    /// MIDI note currently playing, or nil.
    private(set) var playingMidi: Int?

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var sourceNode: AVAudioSourceNode?
    @ObservationIgnored private let sampleRate: Double = 44_100
    @ObservationIgnored private let state = ToneRenderState(sampleRate: 44_100)
    @ObservationIgnored private let amplitude: Double = 0.22

    init() {
        configure()
    }

    private func configure() {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }
        let renderState = state
        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let first = buffers.first,
                  let raw = first.mData else { return noErr }
            let out = raw.assumingMemoryBound(to: Float.self)

            let twoPi = 2.0 * Double.pi
            let increment = twoPi * renderState.targetFrequency / renderState.sampleRate
            let ampTarget = renderState.targetAmplitude
            var localPhase = renderState.phase
            var localAmp = renderState.currentAmplitude
            // Amplitude ramp over ~10 ms.
            let ampStep = 1.0 / (renderState.sampleRate * 0.01)

            var i = 0
            let n = Int(frameCount)
            while i < n {
                if localAmp < ampTarget {
                    localAmp = min(ampTarget, localAmp + ampStep)
                } else if localAmp > ampTarget {
                    localAmp = max(ampTarget, localAmp - ampStep)
                }
                out[i] = Float(sin(localPhase) * localAmp)
                localPhase += increment
                if localPhase > twoPi { localPhase -= twoPi }
                i += 1
            }
            renderState.phase = localPhase
            renderState.currentAmplitude = localAmp
            return noErr
        }
        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: fmt)
        engine.prepare()
    }

    /// Play a sustained tone for a MIDI note at the given A4 reference.
    func play(midi: Int, a4: Double) {
        let freq = NoteMath.frequency(forMidi: midi, a4: a4)
        guard freq > 0 else { return }
        state.targetFrequency = freq

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            return
        }
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            return
        }
        state.targetAmplitude = amplitude
        isPlaying = true
        playingMidi = midi
    }

    /// Retune while playing (no restart needed).
    func retune(midi: Int, a4: Double) {
        let freq = NoteMath.frequency(forMidi: midi, a4: a4)
        guard freq > 0 else { return }
        state.targetFrequency = freq
        playingMidi = midi
    }

    func stop() {
        guard isPlaying else { return }
        // Ramp amplitude to zero, then pause shortly after to avoid a click.
        state.targetAmplitude = 0
        isPlaying = false
        playingMidi = nil
        let engineRef = engine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if engineRef.isRunning { engineRef.pause() }
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }

    func toggle(midi: Int, a4: Double) {
        if isPlaying, playingMidi == midi {
            stop()
        } else if isPlaying {
            retune(midi: midi, a4: a4)
        } else {
            play(midi: midi, a4: a4)
        }
    }
}
