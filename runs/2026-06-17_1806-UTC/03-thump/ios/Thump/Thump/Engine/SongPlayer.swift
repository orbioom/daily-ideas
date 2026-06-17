import SwiftUI
import Observation

/// Plays a Song by driving the shared `SequencerStore`/`AudioEngine` through
/// the chained sections. It listens for the engine's loop callback to advance
/// repeats and sections automatically.
@MainActor
@Observable
final class SongPlayer {
    struct Step: Identifiable {
        let id = UUID()
        let patternName: String
        let grid: StepGrid
        let bpm: Double
        let swing: Double
        let kitID: String
        let repeats: Int
    }

    private(set) var isPlaying = false
    private(set) var currentSectionIndex = 0
    private(set) var currentRepeat = 0

    private var steps: [Step] = []
    private let store: SequencerStore

    init(store: SequencerStore) {
        self.store = store
    }

    var activeSectionID: Int? { isPlaying ? currentSectionIndex : nil }

    /// Build the play queue from resolved sections (pattern lookups done by caller).
    func play(steps: [Step]) {
        guard !steps.isEmpty else { return }
        self.steps = steps
        currentSectionIndex = 0
        currentRepeat = 0
        isPlaying = true
        store.audio.onLoop = { [weak self] in
            self?.advanceOnLoop()
        }
        loadCurrent(startTransport: true)
    }

    func stop() {
        isPlaying = false
        store.audio.onLoop = nil
        store.stop()
    }

    private func loadCurrent(startTransport: Bool) {
        guard steps.indices.contains(currentSectionIndex) else { stop(); return }
        let step = steps[currentSectionIndex]
        store.grid = step.grid
        store.bpm = step.bpm
        store.swing = step.swing
        store.audio.grid = step.grid
        store.audio.bpm = step.bpm
        store.audio.swing = step.swing
        if store.kitID != step.kitID {
            store.kitID = step.kitID
            Task {
                await store.audio.loadKit(KitLibrary.kit(id: step.kitID))
                if startTransport && isPlaying && !store.audio.isPlaying {
                    store.audio.start()
                }
            }
        } else if startTransport && !store.audio.isPlaying {
            store.audio.start()
        }
    }

    /// Called each time the engine grid wraps to step 0.
    private func advanceOnLoop() {
        guard isPlaying else { return }
        guard steps.indices.contains(currentSectionIndex) else { stop(); return }
        let step = steps[currentSectionIndex]
        currentRepeat += 1
        if currentRepeat >= max(1, step.repeats) {
            currentRepeat = 0
            currentSectionIndex += 1
            if currentSectionIndex >= steps.count {
                // End of song.
                stop()
                return
            }
            loadCurrent(startTransport: false)
        }
    }
}
