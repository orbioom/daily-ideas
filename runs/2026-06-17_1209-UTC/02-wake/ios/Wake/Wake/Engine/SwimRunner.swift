import Foundation
import Observation

/// A single rep within a runnable workout, flattened from sets for guiding.
struct RunnerRep: Identifiable {
    let id = UUID()
    let setIndex: Int
    let repIndex: Int        // 0-based within the set
    let repsInSet: Int
    let stroke: Stroke
    let distanceMeters: Double
    let sendOffSeconds: Int
    let restSeconds: Int
    let effort: Effort
    let note: String
}

/// A recorded split for one rep.
struct RecordedRep: Identifiable {
    let id = UUID()
    let setIndex: Int
    let stroke: Stroke
    let distanceMeters: Double
    let timeSeconds: Double
    let restSeconds: Int
}

/// The phase the runner is in.
enum RunnerPhase: Equatable {
    case ready          // not started
    case swimming       // clock running for the current rep
    case resting        // counting down rest before next rep
    case finished       // all reps done, ready to save
}

/// Drives a guided swim. Wall-clock based: every elapsed value derives from a stored
/// anchor Date, so backgrounding, locking, or relaunch never lose time.
@Observable
final class SwimRunner: Identifiable {
    let id = UUID()
    let reps: [RunnerRep]
    let poolLengthMeters: Double
    let workoutName: String?
    let isFreeSwim: Bool

    private(set) var phase: RunnerPhase = .ready
    private(set) var currentIndex: Int = 0
    private(set) var recorded: [RecordedRep] = []

    /// When the current swimming rep started (wall clock).
    private(set) var repStartedAt: Date?
    /// When the current rest started (wall clock).
    private(set) var restStartedAt: Date?
    /// Accumulated total swim time, for the running total display.
    private(set) var sessionStartedAt: Date?

    init(reps: [RunnerRep], poolLengthMeters: Double, workoutName: String?, isFreeSwim: Bool) {
        self.reps = reps
        self.poolLengthMeters = max(1, poolLengthMeters)
        self.workoutName = workoutName
        self.isFreeSwim = isFreeSwim
    }

    var totalReps: Int { reps.count }

    var currentRep: RunnerRep? { reps[safe: currentIndex] }

    var nextRep: RunnerRep? { reps[safe: currentIndex + 1] }

    /// Distance recorded so far, in meters.
    var recordedDistance: Double {
        recorded.reduce(0) { $0 + $1.distanceMeters }
    }

    /// Total swim time recorded so far.
    var recordedTime: Double {
        recorded.reduce(0) { $0 + $1.timeSeconds }
    }

    // MARK: - Elapsed (wall-clock derived)

    /// Seconds the current rep has been swimming, at `now`.
    func swimElapsed(at now: Date) -> Double {
        guard let start = repStartedAt else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    /// Seconds remaining in the current rest, at `now` (can be negative if over).
    func restRemaining(at now: Date) -> Double {
        guard let start = restStartedAt, let rep = currentRep else { return 0 }
        let target = restTarget(for: rep)
        guard target > 0 else { return 0 }
        let elapsed = max(0, now.timeIntervalSince(start))
        return target - elapsed
    }

    /// The rest target after the rep we just completed.
    private func restTarget(for rep: RunnerRep) -> Double {
        if rep.sendOffSeconds > 0 {
            // Rest is whatever's left of the interval after swimming.
            let used = recorded.last?.timeSeconds ?? 0
            return max(0, Double(rep.sendOffSeconds) - used)
        }
        return Double(rep.restSeconds)
    }

    // MARK: - Transitions

    func start(at now: Date = .now) {
        guard phase == .ready, !reps.isEmpty else { return }
        sessionStartedAt = now
        beginSwim(at: now)
    }

    private func beginSwim(at now: Date) {
        repStartedAt = now
        restStartedAt = nil
        phase = .swimming
    }

    /// Record the current rep's split (from the swimming clock) and move on.
    func recordSplit(at now: Date = .now) {
        guard phase == .swimming, let rep = currentRep else { return }
        let elapsed = swimElapsed(at: now)
        let entry = RecordedRep(setIndex: rep.setIndex,
                                stroke: rep.stroke,
                                distanceMeters: rep.distanceMeters,
                                timeSeconds: max(0.1, elapsed),
                                restSeconds: max(0, Int(restTarget(for: rep).rounded())))
        recorded.append(entry)

        let target = restTarget(for: rep)
        let isLast = currentIndex >= reps.count - 1
        if isLast {
            finish()
        } else if target > 0 {
            restStartedAt = now
            repStartedAt = nil
            phase = .resting
        } else {
            advanceToNextRep(at: now)
        }
    }

    /// Skip the remaining rest and begin the next rep now.
    func skipRest(at now: Date = .now) {
        guard phase == .resting else { return }
        advanceToNextRep(at: now)
    }

    /// Called by the timeline when rest naturally elapses.
    func completeRestIfDue(at now: Date) {
        guard phase == .resting else { return }
        if restRemaining(at: now) <= 0 {
            advanceToNextRep(at: now)
        }
    }

    private func advanceToNextRep(at now: Date) {
        currentIndex += 1
        if currentIndex >= reps.count {
            finish()
        } else {
            beginSwim(at: now)
        }
    }

    func finish() {
        phase = .finished
        repStartedAt = nil
        restStartedAt = nil
    }

    /// Re-anchor clocks after returning from background so elapsed values stay truthful.
    /// Because all elapsed values derive from stored Dates, nothing needs adjusting —
    /// but a resting rep may have completed while away.
    func reconcile(at now: Date) {
        completeRestIfDue(at: now)
    }

    // MARK: - Build CompletedSets for saving

    /// Group recorded reps back into CompletedSet rows by their originating set.
    func buildCompletedSets() -> [CompletedSet] {
        var grouped: [Int: [RecordedRep]] = [:]
        for r in recorded {
            grouped[r.setIndex, default: []].append(r)
        }
        var result: [CompletedSet] = []
        var order = 0
        for key in grouped.keys.sorted() {
            guard let group = grouped[key], let first = group.first else { continue }
            let totalTime = group.reduce(0) { $0 + $1.timeSeconds }
            let avgRest = group.isEmpty ? 0 : group.reduce(0) { $0 + $1.restSeconds } / group.count
            let set = CompletedSet(order: order,
                                   stroke: first.stroke,
                                   repeats: group.count,
                                   distancePerRepMeters: first.distanceMeters,
                                   actualTimeSeconds: totalTime,
                                   restSeconds: avgRest,
                                   strokeCountPerLength: nil)
            result.append(set)
            order += 1
        }
        return result
    }

    /// Flatten a workout's sets into a sequence of reps.
    static func reps(from workout: SwimWorkout) -> [RunnerRep] {
        var result: [RunnerRep] = []
        for set in workout.orderedSets {
            let count = max(1, set.repeats)
            for r in 0..<count {
                result.append(RunnerRep(setIndex: set.order,
                                        repIndex: r,
                                        repsInSet: count,
                                        stroke: set.stroke,
                                        distanceMeters: set.distancePerRepMeters,
                                        sendOffSeconds: set.sendOffSeconds,
                                        restSeconds: set.restSeconds,
                                        effort: set.effort,
                                        note: set.note))
            }
        }
        return result
    }
}
