import Foundation
import AVFoundation
import AVFAudio
import Observation
import os

/// The real-time synthesis core. ONE `AVAudioEngine` drives a single
/// `AVAudioSourceNode` whose render block sums every active generator (scaled by
/// its gain and the master gain) and soft-clamps to [-1, 1]. No audio files are
/// used anywhere — every sample is synthesized on device.
///
/// Threading model: SwiftUI mutates parameters on the main thread; the render
/// block runs on the real-time audio thread. Parameters cross the boundary via
/// an `os_unfair_lock`-guarded value snapshot (`Params`) that the render block
/// copies once per callback. Generator DSP state lives in a fixed array indexed
/// by `SoundType.allCases` order and is only ever touched on the audio thread.
@Observable
final class SoundEngine {

    // MARK: - Observable UI-facing state (main thread)

    /// Per-sound UI state, in `SoundType.allCases` order.
    private(set) var sounds: [SoundState]
    var masterVolume: Double {
        didSet { masterVolume = min(1, max(0, masterVolume)); pushParams() }
    }
    private(set) var isPlaying: Bool = false
    /// Set to a calm message if the audio session/engine could not start.
    private(set) var engineError: String?

    /// UI state for one sound.
    struct SoundState: Identifiable {
        let type: SoundType
        var isEnabled: Bool
        var volume: Double
        var id: SoundType { type }
    }

    // MARK: - Audio plumbing
    // All of the following is internal plumbing the audio thread touches; it is
    // explicitly excluded from Observation so render-thread writes never trip
    // the observation machinery on the main actor.

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var sourceNode: AVAudioSourceNode?
    @ObservationIgnored private let sampleRate: Double = 44_100
    @ObservationIgnored private var didConfigureSession = false

    // MARK: - Real-time parameter snapshot (lock-guarded)

    /// A plain value snapshot copied by the render block each callback.
    private struct Params {
        /// Per-generator gain (0 when disabled), in allCases order.
        var gains: [Float]
        var master: Float
        var targetMaster: Float   // for the timer fade ramp
        var rampPerSample: Float  // amount to move `master` toward target each sample
    }

    /// Heap-allocated lock so its address is stable and safe to capture in the
    /// render closure for the engine's lifetime (freed in `deinit`).
    @ObservationIgnored private let lock: UnsafeMutablePointer<os_unfair_lock_s> = {
        let p = UnsafeMutablePointer<os_unfair_lock_s>.allocate(capacity: 1)
        p.initialize(to: os_unfair_lock_s())
        return p
    }()
    @ObservationIgnored private var params: Params

    // MARK: - Generator bank (audio thread only)

    /// Boxed generators so the render closure can mutate them in place without
    /// reallocating. Indexed in `SoundType.allCases` order.
    private final class GenBank {
        var gens: [SoundGenerator]
        init(sampleRate: Float) {
            gens = SoundType.allCases.enumerated().map { idx, type in
                SoundEngine.makeGenerator(for: type, seed: UInt64(idx + 1) &* 0x100000001B3, sampleRate: sampleRate)
            }
        }
    }
    @ObservationIgnored private let bank: GenBank

    // MARK: - Init

    init() {
        let types = SoundType.allCases
        sounds = types.map { SoundState(type: $0, isEnabled: false, volume: $0.defaultVolume) }
        masterVolume = 0.8
        params = Params(gains: Array(repeating: 0, count: types.count),
                        master: 0.8,
                        targetMaster: 0.8,
                        rampPerSample: 0)
        bank = GenBank(sampleRate: Float(sampleRate))
    }

    deinit {
        engine.stop()
        lock.deinitialize(count: 1)
        lock.deallocate()
    }

    // MARK: - Generator factory

    private static func makeGenerator(for type: SoundType, seed: UInt64, sampleRate: Float) -> SoundGenerator {
        switch type {
        case .white:  return WhiteNoiseGen(seed: seed)
        case .pink:   return PinkNoiseGen(seed: seed)
        case .brown:  return BrownNoiseGen(seed: seed)
        case .rain:   return RainGen(seed: seed, sampleRate: sampleRate)
        case .ocean:  return OceanGen(seed: seed, sampleRate: sampleRate)
        case .wind:   return WindGen(seed: seed, sampleRate: sampleRate)
        case .stream: return StreamGen(seed: seed, sampleRate: sampleRate)
        case .fan:    return FanGen(seed: seed, sampleRate: sampleRate)
        case .fire:   return FireGen(seed: seed, sampleRate: sampleRate)
        case .night:  return NightGen(seed: seed, sampleRate: sampleRate)
        }
    }

    // MARK: - Public derived state

    var activeSounds: [SoundState] { sounds.filter { $0.isEnabled } }
    var activeCount: Int { sounds.reduce(0) { $0 + ($1.isEnabled ? 1 : 0) } }
    var hasActiveSound: Bool { activeCount > 0 }

    func state(for type: SoundType) -> SoundState? {
        sounds.first { $0.type == type }
    }

    func isEnabled(_ type: SoundType) -> Bool {
        sounds.first { $0.type == type }?.isEnabled ?? false
    }

    // MARK: - Mutations (main thread)

    /// Toggle a sound on/off. Returns the new enabled state.
    @discardableResult
    func toggle(_ type: SoundType) -> Bool {
        guard let idx = sounds.firstIndex(where: { $0.type == type }) else { return false }
        sounds[idx].isEnabled.toggle()
        pushParams()
        return sounds[idx].isEnabled
    }

    func setEnabled(_ type: SoundType, _ enabled: Bool) {
        guard let idx = sounds.firstIndex(where: { $0.type == type }) else { return }
        sounds[idx].isEnabled = enabled
        pushParams()
    }

    func setVolume(_ type: SoundType, _ volume: Double) {
        guard let idx = sounds.firstIndex(where: { $0.type == type }) else { return }
        sounds[idx].volume = min(1, max(0, volume))
        pushParams()
    }

    /// Disable every sound (used by "clear" and when loading an empty mix).
    func clearAll() {
        for i in sounds.indices { sounds[i].isEnabled = false }
        pushParams()
    }

    /// Replace the active set with the supplied layers (used by mix loading).
    func apply(layers: [(type: SoundType, volume: Double)]) {
        for i in sounds.indices { sounds[i].isEnabled = false }
        for layer in layers {
            guard let idx = sounds.firstIndex(where: { $0.type == layer.type }) else { continue }
            sounds[idx].isEnabled = true
            sounds[idx].volume = min(1, max(0, layer.volume))
        }
        pushParams()
    }

    /// The active layers as engine-ready pairs (for saving a mix).
    var currentLayers: [(type: SoundType, volume: Double)] {
        sounds.filter { $0.isEnabled }.map { ($0.type, $0.volume) }
    }

    // MARK: - Transport

    func play() {
        guard !isPlaying else { return }
        guard hasActiveSound else { return }
        // Cancel any in-progress fade and restore the master to its UI value.
        cancelFadeRamp()
        if !startEngineIfNeeded() { return }
        isPlaying = true
    }

    func pause() {
        guard isPlaying else { return }
        engine.pause()
        isPlaying = false
    }

    func stop() {
        engine.stop()
        isPlaying = false
        cancelFadeRamp()
    }

    func togglePlayback() {
        isPlaying ? pause() : play()
    }

    // MARK: - Timer fade

    /// Begin ramping the master gain to zero over `seconds`, sample-accurately
    /// on the audio thread, then the caller stops playback when the countdown
    /// reaches zero. A 0 or negative interval stops immediately.
    func beginFadeOut(seconds: Double) {
        let total = max(0, seconds) * sampleRate
        os_unfair_lock_lock(lock)
        params.targetMaster = 0
        params.rampPerSample = total > 0 ? params.master / Float(total) : params.master
        os_unfair_lock_unlock(lock)
    }

    /// Cancel a fade and restore the live master gain.
    func cancelFadeRamp() {
        os_unfair_lock_lock(lock)
        params.targetMaster = Float(masterVolume)
        params.master = Float(masterVolume)
        params.rampPerSample = 0
        os_unfair_lock_unlock(lock)
    }

    // MARK: - Parameter push (main → audio)

    /// Copy the current UI parameters into the lock-guarded snapshot. Cheap; the
    /// render block copies it once per callback. Allocation here is fine (main
    /// thread); the audio thread never allocates.
    private func pushParams() {
        var gains = [Float](repeating: 0, count: sounds.count)
        for (i, s) in sounds.enumerated() {
            gains[i] = s.isEnabled ? Float(s.volume) : 0
        }
        let m = Float(masterVolume)
        os_unfair_lock_lock(lock)
        params.gains = gains
        // If not mid-fade, keep master tracking the UI value.
        if params.rampPerSample == 0 {
            params.master = m
            params.targetMaster = m
        }
        os_unfair_lock_unlock(lock)
    }

    // MARK: - Engine / session setup

    /// Configure the audio session and install the source node on first use.
    /// Returns true if the engine is running.
    private func startEngineIfNeeded() -> Bool {
        configureSessionIfNeeded()

        if sourceNode == nil {
            installSourceNode()
        }
        guard sourceNode != nil else {
            engineError = "Hush couldn't start its audio engine. Please try again."
            return false
        }

        do {
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }
            engineError = nil
            return true
        } catch {
            engineError = "Hush couldn't start audio. Check that the device isn't in a restricted mode, then try again."
            isPlaying = false
            return false
        }
    }

    private func configureSessionIfNeeded() {
        guard !didConfigureSession else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            // .playback so sound continues with the silent switch and in the
            // background (UIBackgroundModes: audio in Info.plist).
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            didConfigureSession = true
        } catch {
            engineError = "Hush couldn't activate audio playback. Sound may not play until you reopen the app."
        }
    }

    private func installSourceNode() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            engineError = "Hush couldn't prepare its audio format."
            return
        }

        // Capture the references the render block needs. The closure is
        // `@Sendable`; it touches only the lock-guarded params and the audio-
        // thread-owned generator bank.
        let bankRef = bank

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            return self.render(into: audioBufferList,
                               frameCount: frameCount,
                               bank: bankRef)
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node
    }

    // MARK: - Real-time render (audio thread; allocation-free)

    /// The audio render callback. Reads a parameter snapshot under the lock,
    /// then fills every buffer in the ABL with the summed, limited mix. Guards
    /// all buffer pointers and never allocates.
    private func render(into audioBufferList: UnsafeMutablePointer<AudioBufferList>,
                        frameCount: AVAudioFrameCount,
                        bank: GenBank) -> OSStatus {

        // --- Snapshot parameters under the lock (copy of small value type). ---
        os_unfair_lock_lock(lock)
        var master = params.master
        let targetMaster = params.targetMaster
        let ramp = params.rampPerSample
        // Copy gains into the audio-thread-owned scratch buffer (no allocation:
        // `scratchGains` is sized once at allocCapacity and reused).
        let count = min(scratchGains.count, params.gains.count)
        for i in 0..<count { scratchGains[i] = params.gains[i] }
        for i in count..<scratchGains.count { scratchGains[i] = 0 }
        os_unfair_lock_unlock(lock)

        let frames = Int(frameCount)
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

        // Render the mono mix once into the scratch buffer, then copy to every
        // channel buffer. Guard the scratch size.
        let n = min(frames, scratchMix.count)

        for frame in 0..<n {
            var sample: Float = 0
            // Sum every active generator scaled by its gain. We index `bank.gens`
            // directly (no local copy) so mutating `render()` doesn't trigger a
            // copy-on-write allocation on the audio thread.
            let genCount = bank.gens.count
            for i in 0..<genCount {
                let g = scratchGains[i]
                // Always advance the generator so re-enabling doesn't click,
                // but only mix it in when its gain is above zero.
                let s = bank.gens[i].render()
                if g > 0 { sample += s * g }
            }

            // Advance the master toward its target (timer fade).
            if ramp != 0 {
                if master > targetMaster {
                    master -= ramp
                    if master < targetMaster { master = targetMaster }
                } else if master < targetMaster {
                    master += ramp
                    if master > targetMaster { master = targetMaster }
                }
            }

            sample *= master

            // Soft limiter then hard clamp to [-1, 1].
            sample = softLimit(sample)
            scratchMix[frame] = sample
        }

        // Write the latest master back so the next callback continues the ramp.
        os_unfair_lock_lock(lock)
        params.master = master
        os_unfair_lock_unlock(lock)

        // Copy the mono mix into each channel buffer (guarded).
        for buffer in ablPointer {
            guard let raw = buffer.mData else { continue }
            let floatsAvailable = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
            let writable = min(n, floatsAvailable)
            let ptr = raw.assumingMemoryBound(to: Float.self)
            for frame in 0..<writable {
                ptr[frame] = scratchMix[frame]
            }
            // Zero any frames we didn't fill (defensive; rarely needed).
            if writable < floatsAvailable {
                for frame in writable..<floatsAvailable { ptr[frame] = 0 }
            }
        }

        return noErr
    }

    /// A gentle tanh-like soft limiter to tame summed peaks, then hard clamp.
    @inline(__always)
    private func softLimit(_ x: Float) -> Float {
        // Cheap cubic soft clip for |x| < 1.5, hard clamp beyond.
        let t = max(-1.5, min(1.5, x))
        let shaped = t - (t * t * t) / 6.75   // ≈ soft saturation
        if shaped > 1 { return 1 }
        if shaped < -1 { return -1 }
        return shaped
    }

    // MARK: - Audio-thread scratch (allocated once, never on the audio thread)

    /// Reused mono mix buffer (sized generously for typical buffer sizes).
    /// Allocated once at init; never resized or reallocated on the audio thread.
    @ObservationIgnored private var scratchMix = [Float](repeating: 0, count: 8192)
    /// Reused gains scratch sized to the generator count (allocated at init).
    @ObservationIgnored private var scratchGains = [Float](repeating: 0, count: SoundType.allCases.count)
}
