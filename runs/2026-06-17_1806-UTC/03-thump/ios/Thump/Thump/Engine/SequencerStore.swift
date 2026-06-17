import SwiftUI
import Observation

/// The app-wide live session: the current editable grid, transport params,
/// selected kit and per-track mixer state. It owns the `AudioEngine` and keeps
/// the engine's read-snapshots in sync.
///
/// Uses `@Observable` (not `@StateObject`) and is injected via `.environment`.
@MainActor
@Observable
final class SequencerStore {
    // Live, editable state.
    var grid = StepGrid(stepCount: 16)
    var tracks = TrackState.defaults()
    var bpm: Double = 120
    var swing: Double = 0.0
    var kitID: String = "classic808"

    // Pro-aware step length.
    var maxSteps: Int { isPro ? Pro.proStepCount : Pro.freeStepCount }
    private(set) var isPro: Bool = false

    /// The audio engine (an `@Observable`) — its transport state is observed
    /// by views through `store.audio`.
    @ObservationIgnored let audio: AudioEngine

    init(audio: AudioEngine) {
        self.audio = audio
        audio.bpm = bpm
        audio.swing = swing
        audio.grid = grid
        audio.tracks = tracks
    }

    var kit: Kit { KitLibrary.kit(id: kitID) }

    // MARK: - Pro

    func updatePro(_ value: Bool) {
        isPro = value
        // If downgraded while on a 32-step grid, fold back to 16.
        if !value && grid.stepCount > Pro.freeStepCount {
            setStepCount(Pro.freeStepCount)
        }
        // If current kit is Pro-only and not unlocked, fall back to a free kit.
        if !value && kit.requiresPro {
            selectKit(KitLibrary.freeKits.first?.id ?? "classic808")
        }
    }

    // MARK: - Sync to engine

    private func sync() {
        audio.bpm = bpm
        audio.swing = swing
        audio.grid = grid
        audio.tracks = tracks
    }

    // MARK: - Transport

    func togglePlay() {
        if audio.isPlaying {
            audio.stop()
        } else {
            sync()
            audio.start()
        }
    }

    func stop() { audio.stop() }

    var isPlaying: Bool { audio.isPlaying }
    var currentStep: Int { audio.currentStep }

    // MARK: - Editing

    func toggle(track: Int, step: Int) {
        grid.toggle(track: track, step: step)
        audio.grid = grid
    }

    func toggleAccent(track: Int, step: Int) {
        guard isPro else { return }
        grid.toggleAccent(track: track, step: step)
        audio.grid = grid
    }

    func clearPattern() {
        grid.clear()
        audio.grid = grid
    }

    func setBPM(_ value: Double) {
        bpm = min(200, max(60, value)).rounded()
        audio.bpm = bpm
    }

    func setSwing(_ value: Double) {
        swing = min(0.6, max(0.0, value))
        audio.swing = swing
    }

    func setStepCount(_ count: Int) {
        let allowed = isPro ? count : min(count, Pro.freeStepCount)
        grid.resize(to: allowed)
        audio.grid = grid
    }

    func setMute(track: Int, _ muted: Bool) {
        guard tracks.indices.contains(track) else { return }
        tracks[track].muted = muted
        audio.tracks = tracks
    }

    func setVolume(track: Int, _ volume: Double) {
        guard tracks.indices.contains(track) else { return }
        tracks[track].volume = min(1, max(0, volume))
        audio.tracks = tracks
    }

    // MARK: - Kit

    func selectKit(_ id: String) {
        kitID = id
        Task { await audio.loadKit(KitLibrary.kit(id: id)) }
    }

    /// Ensure the current kit's buffers are loaded (e.g. on first appear).
    func ensureKitLoaded() async {
        if audio.loadedKitID != kitID {
            await audio.loadKit(kit)
        }
    }

    // MARK: - Patterns

    func load(pattern: Pattern) {
        audio.stop()
        var g = pattern.grid
        if !isPro && g.stepCount > Pro.freeStepCount {
            g.resize(to: Pro.freeStepCount)
        }
        grid = g
        bpm = min(200, max(60, pattern.bpm))
        swing = min(0.6, max(0, pattern.swing))
        let targetKit = KitLibrary.kit(id: pattern.kitID)
        kitID = (!isPro && targetKit.requiresPro) ? (KitLibrary.freeKits.first?.id ?? "classic808") : pattern.kitID
        sync()
        Task { await audio.loadKit(KitLibrary.kit(id: kitID)) }
    }

    /// Snapshot the current session into a new (unsaved) Pattern.
    func makePattern(named name: String) -> Pattern {
        Pattern(name: name, bpm: bpm, swing: swing, kitID: kitID, grid: grid, isBuiltIn: false)
    }

    func previewVoice(_ voice: DrumVoice) {
        audio.previewVoice(voice)
    }
}
