import Foundation
import Observation

/// Live, wall-clock training session timer. Anchored to a start date so it stays
/// accurate across scenePhase changes; paused time is accumulated separately.
@Observable
final class SessionEngine {
    let trickId: String

    private(set) var reps: Int = 0
    private(set) var isPaused: Bool = false
    private(set) var isRunning: Bool = false

    /// When the current running segment began.
    private var segmentStart: Date?
    /// Accumulated seconds from completed (paused) segments.
    private var accumulated: TimeInterval = 0

    init(trickId: String) {
        self.trickId = trickId
    }

    func start(now: Date = Date()) {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        segmentStart = now
    }

    func pause(now: Date = Date()) {
        guard isRunning, !isPaused else { return }
        if let s = segmentStart {
            accumulated += max(0, now.timeIntervalSince(s))
        }
        segmentStart = nil
        isPaused = true
    }

    func resume(now: Date = Date()) {
        guard isRunning, isPaused else { return }
        isPaused = false
        segmentStart = now
    }

    /// Total elapsed seconds at the given moment. Computed against wall clock so it
    /// stays correct even if the app was backgrounded.
    func elapsedSeconds(at now: Date = Date()) -> Int {
        var total = accumulated
        if !isPaused, let s = segmentStart {
            total += max(0, now.timeIntervalSince(s))
        }
        return Int(total.rounded(.down))
    }

    func addRep() { reps += 1 }
    func removeRep() { reps = max(0, reps - 1) }

    /// Snapshot used when saving a session. `at` lets callers anchor to the finish time.
    func finalDurationSeconds(at now: Date = Date()) -> Int {
        elapsedSeconds(at: now)
    }
}
