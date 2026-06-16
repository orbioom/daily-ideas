import Foundation
import AVFoundation

/// Calm, named errors surfaced to the UI instead of crashing.
enum AudioEngineError: LocalizedError {
    case sessionUnavailable
    case engineStartFailed

    var errorDescription: String? {
        switch self {
        case .sessionUnavailable:
            return "Audio is unavailable right now. Make sure the device isn't in Silent-only mode and try again."
        case .engineStartFailed:
            return "The tone generator couldn't start. Reconnect your headphones and try once more."
        }
    }
}

/// Real, on-device sine-tone synthesis via AVAudioEngine + AVAudioSourceNode.
/// No audio files — every tone is generated sample-by-sample.
///
/// Mapping a relative dB-HL-ish level to linear gain:
///   gain = pow(10, (level - maxLevel) / 20), clamped to [0, 1].
/// At `level == maxLevel` gain is 1.0 (loudest the screening will produce); softer tests are quieter.
final class AudioEngine {

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double

    // Render-thread state (read on audio thread, written on main; kept atomic-ish via simple Float/Bool).
    private var phase: Double = 0
    private var phaseIncrement: Double = 0
    private var targetGain: Float = 0
    private var currentGain: Float = 0      // smoothed to avoid clicks
    private var pan: Float = 0
    private var isToneOn = false

    private(set) var isRunning = false

    init() {
        sampleRate = AVAudioSession.sharedInstance().sampleRate > 0
            ? AVAudioSession.sharedInstance().sampleRate
            : 44_100
    }

    /// Convert the app's relative level to a clamped linear gain.
    static func gain(forLevel level: Double, maxLevel: Double) -> Float {
        let safeMax = max(maxLevel, 1)
        let raw = pow(10.0, (level - safeMax) / 20.0)
        return Float(min(1.0, max(0.0, raw)))
    }

    /// Prepare the audio session + engine. Safe to call repeatedly; throws a calm error on failure.
    func prepare() throws {
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            throw AudioEngineError.sessionUnavailable
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        guard let format else { throw AudioEngineError.engineStartFailed }

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let smoothing: Float = 0.0015 // per-sample gain glide to prevent clicks

            // Resolve channel buffers (stereo expected).
            let leftBuf = abl.count > 0 ? abl[0].mData?.assumingMemoryBound(to: Float.self) : nil
            let rightBuf = abl.count > 1 ? abl[1].mData?.assumingMemoryBound(to: Float.self) : leftBuf

            // Constant-power pan from [-1,1].
            let panNorm = (self.pan + 1) * 0.5 // 0...1
            let leftPan = cosf(panNorm * Float.pi / 2)
            let rightPan = sinf(panNorm * Float.pi / 2)

            for frame in 0..<Int(frameCount) {
                let goal: Float = self.isToneOn ? self.targetGain : 0
                self.currentGain += (goal - self.currentGain) * smoothing
                let sample = Float(sin(self.phase)) * self.currentGain

                self.phase += self.phaseIncrement
                if self.phase >= twoPi { self.phase -= twoPi }

                leftBuf?[frame] = sample * leftPan
                if let rightBuf, rightBuf != leftBuf {
                    rightBuf[frame] = sample * rightPan
                }
            }
            return noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0

        do {
            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            throw AudioEngineError.engineStartFailed
        }
    }

    /// Begin (or update) a tone. Gain is derived from `level` against `maxLevel`.
    func start(frequency: Int, level: Double, maxLevel: Double, ear: Ear) {
        phaseIncrement = 2.0 * Double.pi * Double(frequency) / sampleRate
        targetGain = AudioEngine.gain(forLevel: level, maxLevel: maxLevel)
        pan = ear.pan
        isToneOn = true
    }

    /// Play a free-running tone for the Tools (sweep / tinnitus matcher) with explicit linear gain.
    func startContinuous(frequency: Double, linearGain: Float, ear: Ear) {
        phaseIncrement = 2.0 * Double.pi * frequency / sampleRate
        targetGain = min(1, max(0, linearGain))
        pan = ear.pan
        isToneOn = true
    }

    /// Silence the tone but keep the engine warm for the next presentation.
    func stop() {
        isToneOn = false
        targetGain = 0
    }

    /// Fully tear down: stop tone, stop engine, deactivate session.
    func teardown() {
        isToneOn = false
        targetGain = 0
        if isRunning {
            engine.stop()
        }
        if let node = sourceNode {
            engine.detach(node)
            sourceNode = nil
        }
        isRunning = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    deinit {
        teardown()
    }
}
