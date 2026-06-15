import Foundation
import SwiftUI

/// Drives a guided routine: a wall-clock player stepping through each exercise with a
/// per-exercise countdown. The view supplies elapsed time from a TimelineView so this model
/// stays a pure, testable state machine (no internal Timer to leak).
@MainActor
final class RoutinePlayer: ObservableObject {
    let routine: EyeRoutine

    @Published private(set) var index: Int = 0
    @Published var isPaused: Bool = false
    @Published private(set) var isFinished: Bool = false

    /// Seconds already spent on the current exercise (accumulated across pauses).
    @Published private(set) var elapsedInExercise: Double = 0

    /// Wall-clock anchor for the current running segment, or nil while paused.
    private var segmentStart: Date?

    /// Nonisolated so a SwiftUI `View.init` can construct it for `@StateObject` without
    /// crossing actor boundaries (it only assigns stored properties).
    nonisolated init(routine: EyeRoutine) {
        self.routine = routine
    }

    var exercises: [EyeExercise] { routine.exercises }

    var current: EyeExercise? {
        guard exercises.indices.contains(index) else { return nil }
        return exercises[index]
    }

    var exerciseCount: Int { exercises.count }

    /// 1-based position for display.
    var position: Int { min(index + 1, max(1, exerciseCount)) }

    /// Whole seconds remaining in the current exercise (guarded).
    var remainingSeconds: Int {
        guard let current else { return 0 }
        let remaining = Double(current.seconds) - elapsedInExercise
        return Int(max(0, remaining.rounded(.up)))
    }

    /// Progress through the current exercise, 0...1.
    var exerciseProgress: Double {
        guard let current, current.seconds > 0 else { return 0 }
        return min(1, max(0, elapsedInExercise / Double(current.seconds)))
    }

    /// Overall routine progress, 0...1, guarded against empty routines.
    var overallProgress: Double {
        guard exerciseCount > 0 else { return isFinished ? 1 : 0 }
        let done = Double(index) + exerciseProgress
        return min(1, max(0, done / Double(exerciseCount)))
    }

    func start() {
        guard !exercises.isEmpty else {
            isFinished = true
            return
        }
        segmentStart = .now
        isPaused = false
    }

    /// Called by the TimelineView on each tick with the current wall-clock time.
    func tick(now: Date) {
        guard !isPaused, !isFinished, let current, let start = segmentStart else { return }
        let liveElapsed = elapsedInExercise + max(0, now.timeIntervalSince(start))
        if liveElapsed >= Double(current.seconds) {
            advance()
        } else {
            elapsedInExercise = liveElapsed
        }
    }

    func togglePause() {
        if isPaused {
            // Resume: re-anchor the segment.
            segmentStart = .now
            isPaused = false
        } else {
            // Pause: bank the elapsed time.
            if let start = segmentStart {
                elapsedInExercise += max(0, Date.now.timeIntervalSince(start))
            }
            segmentStart = nil
            isPaused = true
        }
    }

    func skip() {
        advance()
    }

    private func advance() {
        if index + 1 < exerciseCount {
            index += 1
            elapsedInExercise = 0
            segmentStart = isPaused ? nil : .now
        } else {
            finish()
        }
    }

    private func finish() {
        elapsedInExercise = 0
        segmentStart = nil
        isFinished = true
    }

    /// Total guided seconds actually offered (full routine length).
    var totalSeconds: Int { routine.totalSeconds }
}
