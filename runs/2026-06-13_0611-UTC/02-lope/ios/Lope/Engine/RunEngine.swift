import Foundation
import SwiftUI
import UIKit

/// Drives a guided run-walk session off the wall clock so it keeps correct
/// time even if the app is backgrounded mid-run. All access happens on the
/// main thread (UI callbacks and a main-runloop timer).
@Observable
final class RunEngine {
    let workout: Workout
    let cumulativeEnds: [Int]          // running total of segment end-times (seconds)

    var startDate: Date
    private(set) var accumulatedPause: TimeInterval = 0
    private(set) var pauseStart: Date?
    private(set) var isFinished = false
    var tick: Date = .now

    var voiceEnabled: Bool
    var hapticsEnabled: Bool

    private var timer: Timer?
    private let speaker = Speaker()
    private var announcedIndex = -1
    private var oneMinuteWarned = false
    private var halfwayWarned = false
    private var countdownFired = -1

    init(workout: Workout, voiceEnabled: Bool, hapticsEnabled: Bool) {
        self.workout = workout
        self.voiceEnabled = voiceEnabled
        self.hapticsEnabled = hapticsEnabled
        var acc = 0
        self.cumulativeEnds = workout.segments.map { acc += $0.seconds; return acc }
        self.startDate = .now
    }

    var totalSeconds: Int { workout.totalSeconds }

    // MARK: lifecycle

    func start() {
        startDate = .now
        accumulatedPause = 0
        pauseStart = nil
        isFinished = false
        announcedIndex = -1
        if voiceEnabled { speaker.configureSession() }
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.update()
        }
        update()
    }

    var isPaused: Bool { pauseStart != nil }

    func togglePause() {
        if let pauseStart {
            accumulatedPause += Date().timeIntervalSince(pauseStart)
            self.pauseStart = nil
        } else {
            pauseStart = Date()
        }
        haptic(.medium)
    }

    func skipSegment() {
        let idx = currentIndex
        guard idx < workout.segments.count - 1 else { finish(); return }
        // Jump start of the next segment by shifting startDate back appropriately.
        let target = idx > 0 ? cumulativeEnds[idx - 1] : 0
        let intoSegment = elapsed - Double(target)
        // advance to the end of this segment
        let remaining = Double(workout.segments[idx].seconds) - intoSegment
        startDate = startDate.addingTimeInterval(-remaining)
        haptic(.light)
        update()
    }

    func finish() {
        isFinished = true
        timer?.invalidate(); timer = nil
        if voiceEnabled {
            speaker.say("Workout complete. Great running.")
        }
        notify(.success)
        speaker.deactivate()
    }

    func stopWithoutFinishing() {
        timer?.invalidate(); timer = nil
        speaker.stop()
        speaker.deactivate()
    }

    // MARK: derived state

    func elapsedTime(at now: Date) -> TimeInterval {
        var e = now.timeIntervalSince(startDate) - accumulatedPause
        if let pauseStart { e -= now.timeIntervalSince(pauseStart) }
        return max(0, e)
    }
    var elapsed: TimeInterval { elapsedTime(at: tick) }

    var currentIndex: Int {
        let e = elapsed
        for (i, end) in cumulativeEnds.enumerated() where e < Double(end) { return i }
        return workout.segments.count - 1
    }

    var currentSegment: Segment { workout.segments[min(currentIndex, workout.segments.count - 1)] }

    var segmentStart: Int { currentIndex > 0 ? cumulativeEnds[currentIndex - 1] : 0 }
    var segmentElapsed: TimeInterval { elapsed - Double(segmentStart) }
    var segmentRemaining: TimeInterval {
        max(0, Double(currentSegment.seconds) - segmentElapsed)
    }
    var segmentProgress: Double {
        guard currentSegment.seconds > 0 else { return 1 }
        return min(1, segmentElapsed / Double(currentSegment.seconds))
    }
    var totalRemaining: TimeInterval { max(0, Double(totalSeconds) - elapsed) }
    var totalProgress: Double {
        guard totalSeconds > 0 else { return 1 }
        return min(1, elapsed / Double(totalSeconds))
    }

    var nextSegment: Segment? {
        let i = currentIndex + 1
        return i < workout.segments.count ? workout.segments[i] : nil
    }

    /// Seconds the runner has actually been active (excludes pause), capped at total.
    var activeSeconds: Int { min(Int(elapsed), totalSeconds) }

    // MARK: tick

    private func update() {
        tick = Date()
        if isPaused { return }

        if elapsed >= Double(totalSeconds) {
            finish(); return
        }

        let idx = currentIndex
        if idx != announcedIndex {
            announcedIndex = idx
            oneMinuteWarned = false
            halfwayWarned = false
            countdownFired = -1
            announceSegment()
        }

        let seg = currentSegment
        let remaining = segmentRemaining
        // one-minute warning for longer running blocks
        if seg.kind == .run, seg.seconds >= 180, !oneMinuteWarned, remaining <= 60, remaining > 58 {
            oneMinuteWarned = true
            if voiceEnabled { speaker.say("One minute left.") }
        }
        // halfway for very long runs
        if seg.kind == .run, seg.seconds >= 600, !halfwayWarned, segmentProgress >= 0.5 {
            halfwayWarned = true
            if voiceEnabled { speaker.say("You're halfway.") }
        }
        // final 3-second countdown haptics before a transition
        let r = Int(ceil(remaining))
        if r <= 3, r >= 1, r != countdownFired {
            countdownFired = r
            haptic(.light)
        }
    }

    private func announceSegment() {
        let seg = currentSegment
        switch seg.kind {
        case .warmup:
            if voiceEnabled { speaker.say("Let's begin with a brisk five-minute warm-up walk.") }
            haptic(.medium)
        case .run:
            if voiceEnabled { speaker.say("Run now.") }
            haptic(.heavy)
        case .walk:
            if voiceEnabled { speaker.say("Walk.") }
            haptic(.medium)
        case .cooldown:
            if voiceEnabled { speaker.say("Nicely done. Cool down with a five-minute walk.") }
            haptic(.medium)
        }
    }

    // MARK: feedback

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
