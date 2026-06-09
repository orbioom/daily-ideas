import AVFoundation

/// Plays and mixes any number of looping sound layers through one audio engine.
/// Each `SoundType` gets a player node that loops its generated buffer; layer
/// volume is the node volume, and `masterVolume` is the engine's output volume.
final class SoundMixer {
    private let engine = AVAudioEngine()
    private var nodes: [SoundType: AVAudioPlayerNode] = [:]
    private var started = false

    var masterVolume: Float = 0.9 {
        didSet { engine.mainMixerNode.outputVolume = max(0, min(masterVolume, 1)) }
    }

    private func ensureStarted() {
        guard !started else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            engine.mainMixerNode.outputVolume = max(0, min(masterVolume, 1))
            try engine.start()
            started = true
        } catch {
            started = false
        }
    }

    private func node(for type: SoundType, format: AVAudioFormat) -> AVAudioPlayerNode {
        if let existing = nodes[type] { return existing }
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        nodes[type] = player
        return player
    }

    /// Start (or restart) a layer looping at the given volume.
    func play(_ type: SoundType, volume: Float) {
        ensureStarted()
        guard started, let buf = NoiseFactory.shared.buffer(for: type) else { return }
        let player = node(for: type, format: buf.format)
        player.volume = max(0, min(volume, 1))
        if !player.isPlaying {
            player.scheduleBuffer(buf, at: nil, options: .loops, completionHandler: nil)
            player.play()
        }
    }

    func setVolume(_ type: SoundType, _ volume: Float) {
        nodes[type]?.volume = max(0, min(volume, 1))
    }

    func stop(_ type: SoundType) {
        nodes[type]?.stop()
    }

    func stopAll() {
        for player in nodes.values { player.stop() }
    }

    /// Fully release the audio session (used when the user stops everything).
    func deactivate() {
        guard started else { return }
        stopAll()
        engine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        started = false
    }
}
