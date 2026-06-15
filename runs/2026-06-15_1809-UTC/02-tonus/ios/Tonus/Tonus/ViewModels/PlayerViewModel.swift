import SwiftUI
import SwiftData

/// Drives a live training session from a wall-clock start Date so it stays correct across
/// backgrounding and scene-phase changes (no ticking counter that can drift).
@MainActor
final class PlayerViewModel: ObservableObject {
    enum Status: Equatable {
        case running
        case paused
        case finished
    }

    let engine: SessionEngine
    let programName: String

    @Published private(set) var status: Status = .running
    /// The phase shown last — used to fire a single cue per phase boundary.
    @Published private(set) var lastPhase: Phase
    @Published private(set) var didLogResult = false

    /// Wall-clock anchor; effective elapsed = (referenceDate - startDate) - accumulatedPause.
    private var startDate: Date
    private var accumulatedPause: TimeInterval = 0
    private var pauseBegan: Date?

    private let hapticsEnabled: Bool
    private let audioEnabled: Bool

    init(program: TrainingProgram, hapticsEnabled: Bool, audioEnabled: Bool) {
        self.engine = SessionEngine(program: program)
        self.programName = program.name
        self.lastPhase = engine.steps.first?.phase ?? .squeeze
        self.startDate = Date()
        self.hapticsEnabled = hapticsEnabled
        self.audioEnabled = audioEnabled
    }

    // MARK: Derived time

    /// Effective elapsed seconds, accounting for pauses.
    func elapsed(at reference: Date) -> Double {
        let raw = reference.timeIntervalSince(startDate) - accumulatedPause
        // While paused, freeze elapsed at the moment pause began.
        if let pauseBegan, status == .paused {
            let frozen = pauseBegan.timeIntervalSince(startDate) - accumulatedPause
            return max(0, frozen)
        }
        return max(0, raw)
    }

    func moment(at reference: Date) -> SessionMoment {
        engine.moment(at: elapsed(at: reference))
    }

    var totalReps: Int { engine.totalReps }
    var totalSets: Int { engine.totalSets }

    /// Called from the TimelineView each tick to detect phase boundaries and completion.
    func tick(at reference: Date) {
        guard status == .running else { return }
        let moment = engine.moment(at: elapsed(at: reference))

        if moment.isComplete {
            finishNaturally()
            return
        }

        if moment.phase != lastPhase {
            lastPhase = moment.phase
            Haptics.soft(enabled: hapticsEnabled)
            AudioCue.phaseChange(enabled: audioEnabled)
        }
    }

    // MARK: Controls

    func pause() {
        guard status == .running else { return }
        status = .paused
        pauseBegan = Date()
        Haptics.tap(enabled: hapticsEnabled)
    }

    func resume() {
        guard status == .paused, let began = pauseBegan else { return }
        accumulatedPause += Date().timeIntervalSince(began)
        pauseBegan = nil
        status = .running
        Haptics.tap(enabled: hapticsEnabled)
    }

    /// User stopped early. Returns the reps completed so far for the summary screen.
    func stopEarly(at reference: Date) -> (reps: Int, seconds: Int) {
        let e = elapsed(at: reference)
        let reps = engine.completedReps(at: e)
        status = .finished
        return (reps, Int(e.rounded()))
    }

    private func finishNaturally() {
        status = .finished
        Haptics.success(enabled: hapticsEnabled)
        AudioCue.complete(enabled: audioEnabled)
    }

    /// Restart the session from zero for a "Repeat" action.
    func restart() {
        startDate = Date()
        accumulatedPause = 0
        pauseBegan = nil
        didLogResult = false
        lastPhase = engine.steps.first?.phase ?? .squeeze
        status = .running
    }

    // MARK: Persistence

    /// Writes a SessionLog. Safe to call once; guarded against double-write.
    func log(into context: ModelContext, finished: Bool, completedReps: Int, durationSeconds: Int) {
        guard !didLogResult else { return }
        let entry = SessionLog(
            date: Date(),
            programName: programName,
            completedReps: max(0, min(totalReps, completedReps)),
            totalReps: totalReps,
            durationSeconds: max(0, durationSeconds),
            finished: finished
        )
        context.insert(entry)
        try? context.save()
        didLogResult = true
    }
}
