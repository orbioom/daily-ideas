import Foundation
import AVFAudio
import Observation

/// Precise metronome. Synthesizes click PCM buffers in code (sine with an
/// exponential-decay envelope — NO audio files) and schedules them on an
/// `AVAudioPlayerNode` at sample-accurate times derived from a wall-clock so the
/// tempo stays rock-steady even under UI load.
@MainActor
@Observable
final class MetronomeEngine {

    // MARK: - Public configuration

    var bpm: Int = 120 { didSet { bpm = min(max(bpm, MetronomeEngine.minBPM), MetronomeEngine.maxBPM) } }
    var timeSignature = TimeSignature(top: 4, bottom: 4)
    var subdivision: Subdivision = .quarter
    var accentFirst = true
    var clickStyle: ClickStyle = .classic { didSet { if clickStyle != oldValue { rebuildClicks() } } }
    var hapticsEnabled = false

    static let minBPM = 30
    static let maxBPM = 300

    // MARK: - Published state

    private(set) var isPlaying = false
    /// Index of the current beat within the measure (0-based). −1 when stopped.
    private(set) var currentBeat = -1
    /// Index of the current click within the beat (for subdivision visuals).
    private(set) var currentClick = -1

    /// Closure invoked on each click so the view can trigger a haptic / pulse.
    @ObservationIgnored var onClick: ((_ beat: Int, _ click: Int, _ accent: Bool) -> Void)?

    // MARK: - Audio

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let player = AVAudioPlayerNode()
    @ObservationIgnored private let sampleRate: Double = 44_100
    @ObservationIgnored private var format: AVAudioFormat?
    @ObservationIgnored private var accentBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var normalBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var subBuffer: AVAudioPCMBuffer?

    // Scheduling bookkeeping.
    @ObservationIgnored private var nextSampleTime: AVAudioFramePosition = 0
    @ObservationIgnored private var scheduledIndex = 0   // global click counter
    @ObservationIgnored private var timer: Timer?

    // MARK: - Tap tempo

    @ObservationIgnored private var tapTimes: [Date] = []

    init() {
        configureAudio()
        rebuildClicks()
    }

    // MARK: - Setup

    private func configureAudio() {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }
        format = fmt
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: fmt)
        engine.prepare()
    }

    /// Build the three click timbres: accent (beat 1), normal (other beats),
    /// and a quieter subdivision click.
    private func rebuildClicks() {
        let style = clickStyle
        accentBuffer = makeClick(frequency: style.baseFrequency * 1.5,
                                 decay: style.decay,
                                 amplitude: 0.95)
        normalBuffer = makeClick(frequency: style.baseFrequency,
                                 decay: style.decay,
                                 amplitude: 0.7)
        subBuffer = makeClick(frequency: style.baseFrequency * 0.9,
                              decay: style.decay * 0.8,
                              amplitude: 0.4)
    }

    /// Synthesize a short click: sine partial shaped by an exponential decay.
    private func makeClick(frequency: Double, decay: Double, amplitude: Double) -> AVAudioPCMBuffer? {
        guard let fmt = format else { return nil }
        let lengthSeconds = max(0.005, min(decay * 4, 0.15))
        let frames = AVAudioFrameCount(sampleRate * lengthSeconds)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let channels = buffer.floatChannelData else { return nil }
        let ptr = channels[0]
        let twoPiF = 2.0 * Double.pi * frequency
        let tau = max(decay, 1e-4)
        var i = 0
        let n = Int(frames)
        while i < n {
            let t = Double(i) / sampleRate
            let env = exp(-t / tau)
            let sample = sin(twoPiF * t) * env * amplitude
            ptr[i] = Float(sample)
            i += 1
        }
        return buffer
    }

    // MARK: - Transport

    func toggle() { isPlaying ? stop() : start() }

    func start() {
        guard !isPlaying else { return }
        guard format != nil else { return }

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

        scheduledIndex = 0
        currentBeat = -1
        currentClick = -1
        // Start a quarter second out so the first click lands cleanly.
        let now = player.lastRenderTime?.sampleTime ?? 0
        nextSampleTime = now + AVAudioFramePosition(sampleRate * 0.25)
        player.play()
        isPlaying = true

        // A lightweight scheduling timer keeps the player's queue topped up.
        scheduleAhead()
        let t = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.scheduleAhead() }
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    func stop() {
        guard isPlaying else { return }
        timer?.invalidate()
        timer = nil
        player.stop()
        engine.pause()
        isPlaying = false
        currentBeat = -1
        currentClick = -1
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    /// Schedule clicks until ~0.4s ahead of the current render time. Each click
    /// time is computed from the integer click index, so timing never drifts.
    private func scheduleAhead() {
        guard isPlaying else { return }
        let framesPerClick = framesPerClick()
        guard framesPerClick > 0 else { return }

        let renderTime = player.lastRenderTime?.sampleTime ?? nextSampleTime
        let horizon = renderTime + AVAudioFramePosition(sampleRate * 0.4)

        // Schedule a bounded number per pass to avoid runaway loops.
        var scheduled = 0
        while nextSampleTime < horizon, scheduled < 32 {
            let clicksPerBeat = max(1, subdivision.clicksPerBeat)
            let beatsPerMeasure = max(1, timeSignature.top)
            let clickInMeasure = scheduledIndex % (clicksPerBeat * beatsPerMeasure)
            let beatInMeasure = clickInMeasure / clicksPerBeat
            let clickInBeat = clickInMeasure % clicksPerBeat
            let isAccent = accentFirst && beatInMeasure == 0 && clickInBeat == 0
            let isDownbeat = clickInBeat == 0

            let buffer: AVAudioPCMBuffer?
            if isAccent {
                buffer = accentBuffer
            } else if isDownbeat {
                buffer = normalBuffer
            } else {
                buffer = subBuffer
            }

            if let buffer, let fmt = format {
                let when = AVAudioTime(sampleTime: nextSampleTime, atRate: fmt.sampleRate)
                let capturedBeat = beatInMeasure
                let capturedClick = clickInBeat
                player.scheduleBuffer(buffer, at: when, options: []) { [weak self] in
                    Task { @MainActor in
                        self?.fireClick(beat: capturedBeat, click: capturedClick, accent: isAccent)
                    }
                }
            }

            nextSampleTime += AVAudioFramePosition(framesPerClick)
            scheduledIndex += 1
            scheduled += 1
        }
    }

    /// Number of audio frames between consecutive clicks for the current tempo.
    private func framesPerClick() -> Double {
        let safeBPM = Double(min(max(bpm, MetronomeEngine.minBPM), MetronomeEngine.maxBPM))
        let clicksPerBeat = Double(max(1, subdivision.clicksPerBeat))
        guard safeBPM > 0, clicksPerBeat > 0 else { return 0 }
        let secondsPerBeat = 60.0 / safeBPM
        let secondsPerClick = secondsPerBeat / clicksPerBeat
        return sampleRate * secondsPerClick
    }

    /// Called (on main) when a scheduled click actually plays — drives visuals.
    private func fireClick(beat: Int, click: Int, accent: Bool) {
        guard isPlaying else { return }
        currentBeat = beat
        currentClick = click
        onClick?(beat, click, accent)
    }

    // MARK: - Tap tempo

    /// Register a tap; averages the intervals of the last few taps into a BPM.
    func tapTempo() {
        let now = Date()
        // Drop stale taps (>2s gap resets the sequence).
        if let last = tapTimes.last, now.timeIntervalSince(last) > 2.0 {
            tapTimes.removeAll()
        }
        tapTimes.append(now)
        if tapTimes.count > 5 { tapTimes.removeFirst() }

        guard tapTimes.count >= 2 else { return }
        var intervals: [Double] = []
        for i in 1..<tapTimes.count {
            guard let a = tapTimes[safe: i - 1], let b = tapTimes[safe: i] else { continue }
            intervals.append(b.timeIntervalSince(a))
        }
        guard !intervals.isEmpty else { return }
        let avg = intervals.reduce(0, +) / Double(intervals.count)
        guard avg > 0 else { return }
        let computed = Int((60.0 / avg).rounded())
        bpm = min(max(computed, MetronomeEngine.minBPM), MetronomeEngine.maxBPM)
    }

    /// Apply a preset's configuration. Restarts cleanly if currently playing.
    func apply(_ preset: MetronomePreset) {
        let wasPlaying = isPlaying
        if wasPlaying { stop() }
        bpm = preset.bpm
        timeSignature = preset.timeSignature
        subdivision = preset.subdivision
        accentFirst = preset.accentFirst
        if wasPlaying { start() }
    }
}
