import SwiftUI

/// The single source of truth for what's playing. Views read/observe this; it
/// owns the audio mixer and the sleep timer. Layer state is kept as a dictionary
/// of active sounds → volume; a global `isPlaying` flag drives the whole mix.
@MainActor
@Observable
final class MixerEngine {
    private let mixer = SoundMixer()

    /// Active layers and their volumes (0…1). Presence of a key = layer enabled.
    private(set) var volumes: [SoundType: Double] = [:]
    private(set) var isPlaying = false

    var defaultLayerVolume: Double = 0.7

    var masterVolume: Double = 0.9 {
        didSet { mixer.masterVolume = Float(masterVolume) }
    }

    // Sleep timer
    private(set) var timerEnd: Date?
    private(set) var timerRemaining: Int = 0
    var fadeSeconds: Double = 30
    private var baseMasterDuringFade: Double = 0.9
    private var timer: Timer?

    var activeCount: Int { volumes.count }
    var isTimerActive: Bool { timerEnd != nil }

    // MARK: - Layers

    func isActive(_ type: SoundType) -> Bool { volumes[type] != nil }

    func volume(for type: SoundType) -> Double { volumes[type] ?? defaultLayerVolume }

    func toggle(_ type: SoundType) {
        if isActive(type) {
            remove(type)
        } else {
            add(type)
        }
    }

    func add(_ type: SoundType) {
        let vol = volumes[type] ?? defaultLayerVolume
        volumes[type] = vol
        if !isPlaying { isPlaying = true }
        mixer.play(type, volume: Float(vol))
    }

    func remove(_ type: SoundType) {
        volumes[type] = nil
        mixer.stop(type)
        if volumes.isEmpty { stop() }
    }

    func setVolume(_ type: SoundType, _ value: Double) {
        let v = min(max(value, 0), 1)
        volumes[type] = v
        mixer.setVolume(type, Float(v))
    }

    func play() {
        guard !volumes.isEmpty else { return }
        isPlaying = true
        for (type, vol) in volumes { mixer.play(type, volume: Float(vol)) }
    }

    func pause() {
        isPlaying = false
        mixer.stopAll()
    }

    /// Stop everything and clear the active layers.
    func stop() {
        isPlaying = false
        cancelTimer()
        mixer.deactivate()
    }

    // MARK: - Mixes

    func apply(_ mix: Mix) {
        mixer.stopAll()
        volumes = [:]
        for layer in mix.layers {
            volumes[layer.sound] = min(max(layer.volume, 0), 1)
        }
        if volumes.isEmpty {
            isPlaying = false
        } else {
            play()
        }
    }

    // MARK: - Sleep timer

    func startTimer(minutes: Int) {
        guard minutes > 0 else { return }
        baseMasterDuringFade = masterVolume
        timerEnd = Date().addingTimeInterval(Double(minutes) * 60)
        scheduleTick()
        if !isPlaying { play() }
    }

    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        timerEnd = nil
        timerRemaining = 0
        mixer.masterVolume = Float(masterVolume)
    }

    private func scheduleTick() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        guard let end = timerEnd else { return }
        let remaining = end.timeIntervalSinceNow
        timerRemaining = max(0, Int(remaining.rounded()))

        if remaining <= 0 {
            // Time's up — stop the mix and reset.
            timer?.invalidate()
            timer = nil
            timerEnd = nil
            mixer.stopAll()
            isPlaying = false
            mixer.masterVolume = Float(masterVolume)
            Haptics.tap()
            return
        }

        // Fade the master volume over the final `fadeSeconds`.
        if remaining <= fadeSeconds, fadeSeconds > 0 {
            let factor = remaining / fadeSeconds
            mixer.masterVolume = Float(baseMasterDuringFade * max(0, min(1, factor)))
        } else {
            mixer.masterVolume = Float(masterVolume)
        }
    }
}
