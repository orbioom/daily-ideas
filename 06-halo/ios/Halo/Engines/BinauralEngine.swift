import AVFoundation
import Foundation

/// BinauralEngine: Core DSP engine for binaural beat generation.
/// Uses AVAudioSourceNode for real-time stereo synthesis.
/// Left channel = carrier frequency, Right channel = carrier + binaural frequency.
/// IMPORTANT: The render block runs on a real-time audio thread.
/// Reads of Double properties are not formally atomic, but on arm64 these
/// are 64-bit aligned loads which are atomic in practice. No locks or
/// allocations occur inside the render block.
@Observable
final class BinauralEngine {

    // MARK: - Observable State
    var isPlaying: Bool = false
    var carrierFrequency: Double = 200.0
    var binauralFrequency: Double = 10.0
    var volume: Float = 0.8 {
        didSet { audioEngine.mainMixerNode.outputVolume = volume }
    }
    var noiseLevel: Float = 0.15
    var sessionPreset: HaloPreset?
    var sessionStartDate: Date?
    var timerDuration: TimeInterval = 0
    var isNoiseEnabled: Bool = false

    // Callback invoked on main thread when session timer completes
    var onSessionComplete: (() -> Void)?

    // MARK: - Private
    private let audioEngine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var noiseSourceNode: AVAudioSourceNode?

    // sampleIndex is read on the audio thread and written only at session start
    // (before the render block is active), which is safe in practice on arm64.
    private var sampleIndex: Int = 0
    private var noiseSampleIndex: Int = 0

    // Pink noise filter state (Kellet's method)
    private var b0: Float = 0
    private var b1: Float = 0
    private var b2: Float = 0
    private var b3: Float = 0
    private var b4: Float = 0
    private var b5: Float = 0
    private var b6: Float = 0

    private var timerCheckTask: Task<Void, Never>?

    // MARK: - Public API

    func start(preset: HaloPreset) {
        stop()
        carrierFrequency = preset.carrierHz
        binauralFrequency = preset.binauralHz
        sessionPreset = preset
        sessionStartDate = Date()
        sampleIndex = 0
        noiseSampleIndex = 0
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; b4 = 0; b5 = 0; b6 = 0

        setupAudioSession()
        setupEngine()
        isPlaying = true

        if timerDuration > 0 {
            startTimerCheck()
        }
    }

    func stop() {
        timerCheckTask?.cancel()
        timerCheckTask = nil
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        // Detach nodes before reset
        if let node = sourceNode {
            audioEngine.detach(node)
            sourceNode = nil
        }
        if let node = noiseSourceNode {
            audioEngine.detach(node)
            noiseSourceNode = nil
        }
        isPlaying = false
        sessionPreset = nil
        sessionStartDate = nil
    }

    func setVolume(_ v: Float) {
        volume = max(0, min(1, v))
    }

    func setTimer(duration: TimeInterval) {
        timerDuration = duration
    }

    var elapsedTime: TimeInterval {
        guard let start = sessionStartDate else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var remainingTime: TimeInterval? {
        guard timerDuration > 0, let start = sessionStartDate else { return nil }
        let remaining = timerDuration - Date().timeIntervalSince(start)
        return max(0, remaining)
    }

    // MARK: - Private: Audio Session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("[BinauralEngine] Audio session error: \(error)")
        }
    }

    // MARK: - Private: Engine Setup

    private func setupEngine() {
        let stereoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!

        // Tone source node: real-time stereo synthesis
        let toneNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return kAudioUnitErr_Uninitialized }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard ablPointer.count >= 2 else { return kAudioUnitErr_FormatNotSupported }

            let leftFreq = self.carrierFrequency
            let rightFreq = self.carrierFrequency + self.binauralFrequency
            let sampleRate = 44100.0
            let amplitude: Float = 0.5

            guard
                let leftData = ablPointer[0].mData?.assumingMemoryBound(to: Float.self),
                let rightData = ablPointer[1].mData?.assumingMemoryBound(to: Float.self)
            else { return kAudioUnitErr_FormatNotSupported }

            for frame in 0..<Int(frameCount) {
                let idx = self.sampleIndex + frame
                let t = Double(idx) / sampleRate
                leftData[frame]  = Float(sin(2.0 * Double.pi * leftFreq  * t)) * amplitude
                rightData[frame] = Float(sin(2.0 * Double.pi * rightFreq * t)) * amplitude
            }
            self.sampleIndex += Int(frameCount)
            // Prevent sampleIndex from growing unbounded (wrap at ~10 minutes of samples)
            if self.sampleIndex > 26_460_000 { self.sampleIndex = 0 }

            return noErr
        }
        self.sourceNode = toneNode
        audioEngine.attach(toneNode)
        audioEngine.connect(toneNode, to: audioEngine.mainMixerNode, format: stereoFormat)

        // Ambient pink noise source node
        let noiseNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return kAudioUnitErr_Uninitialized }
            guard self.isNoiseEnabled else {
                // Fill silence
                let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
                for buf in ablPointer {
                    if let data = buf.mData?.assumingMemoryBound(to: Float.self) {
                        for i in 0..<Int(frameCount) { data[i] = 0 }
                    }
                }
                return noErr
            }

            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let level = self.noiseLevel

            guard ablPointer.count >= 2,
                  let leftData  = ablPointer[0].mData?.assumingMemoryBound(to: Float.self),
                  let rightData = ablPointer[1].mData?.assumingMemoryBound(to: Float.self)
            else { return kAudioUnitErr_FormatNotSupported }

            for frame in 0..<Int(frameCount) {
                let white = Float.random(in: -1...1)
                self.b0 = 0.99886 * self.b0 + white * 0.0555179
                self.b1 = 0.99332 * self.b1 + white * 0.0750759
                self.b2 = 0.96900 * self.b2 + white * 0.1538520
                self.b3 = 0.86650 * self.b3 + white * 0.3104856
                self.b4 = 0.55000 * self.b4 + white * 0.5329522
                self.b5 = -0.7616 * self.b5 - white * 0.0168980
                let pink = self.b0 + self.b1 + self.b2 + self.b3 + self.b4 + self.b5 + self.b6 + white * 0.5362
                self.b6 = white * 0.115926
                let sample = pink * 0.11 * level
                leftData[frame]  = sample
                rightData[frame] = sample
            }
            return noErr
        }
        self.noiseSourceNode = noiseNode
        audioEngine.attach(noiseNode)
        audioEngine.connect(noiseNode, to: audioEngine.mainMixerNode, format: stereoFormat)

        audioEngine.mainMixerNode.outputVolume = volume

        do {
            try audioEngine.start()
        } catch {
            print("[BinauralEngine] Engine start error: \(error)")
        }
    }

    // MARK: - Timer

    private func startTimerCheck() {
        timerCheckTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else { return }
                if let remaining = self.remainingTime, remaining <= 0 {
                    await MainActor.run {
                        self.stop()
                        self.onSessionComplete?()
                    }
                    return
                }
            }
        }
    }
}
