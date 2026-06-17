import AVFoundation
import Foundation
import SwiftUI
import Observation

/// Drives audio for Thump.
///
/// - Synthesizes each of the eight drum voices ONCE into an `AVAudioPCMBuffer`
///   (see `DrumSynth`) for the active kit, then re-uses those buffers.
/// - Each voice owns one `AVAudioPlayerNode` connected to the main mixer.
/// - Playback is a **Timer-driven sequencer** (not sample-accurate): a repeating
///   timer fires every 16th-note (with swing) and schedules the active buffers.
///   This is acceptable timing for a phone groovebox.
///
/// `@MainActor @Observable` so SwiftUI tracks transport state; the audio nodes
/// do their own work on a high-priority queue.
@MainActor
@Observable
final class AudioEngine {

    // MARK: Observable UI state
    private(set) var isPlaying = false
    private(set) var currentStep = 0
    private(set) var isLoadingKit = false
    private(set) var audioAvailable = true
    private(set) var loadedKitID: String = ""

    // MARK: Sequence parameters (set by the store; not observed by UI)
    @ObservationIgnored var bpm: Double = 120
    @ObservationIgnored var swing: Double = 0.0          // 0...1
    @ObservationIgnored var masterVolume: Double = 0.85 { didSet { engine.mainMixerNode.outputVolume = Float(min(1, max(0, masterVolume))) } }
    @ObservationIgnored var metronomeEnabled = false
    @ObservationIgnored var countInEnabled = false

    /// Snapshot the sequencer reads on each tick. Updated by the store.
    @ObservationIgnored var grid = StepGrid(stepCount: 16)
    @ObservationIgnored var tracks = TrackState.defaults()

    // MARK: Audio graph
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let format: AVAudioFormat?
    @ObservationIgnored private var players: [AVAudioPlayerNode] = []
    @ObservationIgnored private var buffers: [DrumVoice: AVAudioPCMBuffer] = [:]
    @ObservationIgnored private var clickBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private let clickPlayer = AVAudioPlayerNode()

    // MARK: Clock
    @ObservationIgnored private var timer: DispatchSourceTimer?
    @ObservationIgnored private var tickParity = false   // toggles each step for swing

    /// Called when the sequencer wraps to step 0 (used by Song mode to advance).
    @ObservationIgnored var onLoop: (() -> Void)?

    init() {
        // Standard mono float format @ 44.1 kHz used for all buffers + connections.
        let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                sampleRate: DrumSynth.sampleRate,
                                channels: 1,
                                interleaved: false)
        self.format = fmt
        configureSession()
        buildGraph()
    }

    // MARK: - Setup

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            audioAvailable = false
        }
    }

    private func buildGraph() {
        guard let format else {
            audioAvailable = false
            return
        }
        for _ in DrumVoice.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }
        engine.attach(clickPlayer)
        engine.connect(clickPlayer, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = Float(min(1, max(0, masterVolume)))

        do {
            try engine.start()
            startAllPlayers()
        } catch {
            audioAvailable = false
        }
        clickBuffer = makeClickBuffer()
    }

    private func startAllPlayers() {
        guard engine.isRunning else { return }
        for node in players where !node.isPlaying { node.play() }
        if !clickPlayer.isPlaying { clickPlayer.play() }
    }

    // MARK: - Kit loading (async synthesis)

    /// Synthesize all eight voice buffers for the given kit off the main actor,
    /// then publish them. Shows a brief loading state.
    func loadKit(_ kit: Kit) async {
        guard let format else {
            audioAvailable = false
            return
        }
        isLoadingKit = true
        let kitID = kit.id
        let params = kit.params

        // Render on a background task; AVAudioPCMBuffer creation is thread-safe here
        // because we only build and return them (no shared mutable graph access).
        let rendered: [DrumVoice: AVAudioPCMBuffer] = await Task.detached(priority: .userInitiated) {
            var result: [DrumVoice: AVAudioPCMBuffer] = [:]
            for voice in DrumVoice.allCases {
                let vp = params[voice] ?? VoiceParams(startFreq: 200, endFreq: 80, decay: 0.2, noiseMix: 0.3, brightness: 0.5, gain: 0.8)
                if let buffer = DrumSynth.makeBuffer(voice: voice, params: vp, format: format) {
                    result[voice] = buffer
                }
            }
            return result
        }.value

        buffers = rendered
        loadedKitID = kitID
        isLoadingKit = false
        // Ensure engine still running after any interruption.
        ensureRunning()
    }

    private func ensureRunning() {
        if !engine.isRunning {
            do {
                try engine.start()
                startAllPlayers()
                audioAvailable = true
            } catch {
                audioAvailable = false
            }
        } else {
            startAllPlayers()
        }
    }

    // MARK: - Transport

    func start() {
        guard !isPlaying else { return }
        ensureRunning()
        guard audioAvailable else { return }
        currentStep = 0
        tickParity = false
        isPlaying = true
        if countInEnabled {
            playCountIn { [weak self] in
                guard let self, self.isPlaying else { return }
                self.scheduleTick(immediate: true)
            }
        } else {
            scheduleTick(immediate: true)
        }
    }

    /// Play a one-bar (4 beat) metronome count-in, then call `completion`.
    private func playCountIn(completion: @escaping () -> Void) {
        let beat = 60.0 / min(300, max(30, bpm))
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + beat * Double(i)) { [weak self] in
                guard let self, self.isPlaying else { return }
                self.playClick(accent: i == 0)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + beat * 4.0, execute: completion)
    }

    func stop() {
        isPlaying = false
        timer?.cancel()
        timer = nil
        currentStep = 0
    }

    /// Audition a single voice (tap a pad). Works whether or not transport runs.
    func previewVoice(_ voice: DrumVoice, accented: Bool = false) {
        ensureRunning()
        trigger(voice: voice, accented: accented, ignoreMute: true)
    }

    // MARK: - Clock

    private func scheduleTick(immediate: Bool) {
        timer?.cancel()
        let interval = stepDuration()
        // Swing: delay odd (off-beat) steps by a fraction of a step.
        let swingDelay = tickParity ? interval * swing * 0.66 : 0.0

        let t = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        let first = (immediate ? 0.0 : interval) + swingDelay
        t.schedule(deadline: .now() + first)
        t.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.fireStep()
            }
        }
        timer = t
        t.resume()
    }

    private func stepDuration() -> Double {
        let safeBpm = min(300, max(30, bpm))
        return 60.0 / safeBpm / 4.0   // 16th notes
    }

    private func fireStep() {
        guard isPlaying else { return }
        let step = currentStep

        // Metronome click on each quarter note.
        if metronomeEnabled, step % 4 == 0 {
            playClick(accent: step == 0)
        }

        for voice in DrumVoice.allCases {
            let track = voice.rawValue
            if grid.isActive(track: track, step: step) {
                let accented = grid.isAccented(track: track, step: step)
                trigger(voice: voice, accented: accented, ignoreMute: false)
            }
        }

        // Advance.
        let next = (step + 1) % max(1, grid.stepCount)
        currentStep = next
        tickParity.toggle()
        if next == 0 { onLoop?() }
        scheduleTick(immediate: false)
    }

    // MARK: - Triggering

    private func trigger(voice: DrumVoice, accented: Bool, ignoreMute: Bool) {
        guard audioAvailable else { return }
        let track = voice.rawValue
        guard players.indices.contains(track) else { return }
        guard let buffer = buffers[voice] else { return }

        let state = tracks.indices.contains(track) ? tracks[track] : TrackState()
        if state.muted && !ignoreMute { return }

        let node = players[track]
        let base = ignoreMute ? 0.9 : state.volume
        let accentBoost = accented ? 1.0 : 0.78
        node.volume = Float(min(1.0, max(0.0, base * accentBoost)))

        if !node.isPlaying { node.play() }
        node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func playClick(accent: Bool) {
        guard let clickBuffer else { return }
        clickPlayer.volume = accent ? 0.7 : 0.45
        if !clickPlayer.isPlaying { clickPlayer.play() }
        clickPlayer.scheduleBuffer(clickBuffer, at: nil, options: .interrupts, completionHandler: nil)
    }

    private func makeClickBuffer() -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let frames = AVAudioFrameCount(Int(0.04 * DrumSynth.sampleRate))
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        guard let ch = buffer.floatChannelData?[0] else { return nil }
        var phase = 0.0
        let n = Int(frames)
        for i in 0..<n {
            let t = Double(i) / DrumSynth.sampleRate
            phase += 2.0 * .pi * 1800.0 / DrumSynth.sampleRate
            let env = exp(-t / 0.01)
            ch[i] = Float(min(1, max(-1, sin(phase) * env * 0.8)))
        }
        return buffer
    }

    deinit {
        timer?.cancel()
    }
}
