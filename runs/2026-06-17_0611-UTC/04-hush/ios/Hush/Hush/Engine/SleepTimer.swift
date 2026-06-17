import Foundation
import Observation

/// Drives the sleep-timer countdown from a stored end `Date` so it survives
/// backgrounding and relaunch (the view reads `remaining(at:)` from a
/// `TimelineView`). When the end is reached the owner triggers the engine's
/// fade-out and stops playback.
@Observable
final class SleepTimer {

    /// The wall-clock instant the timer ends (nil when inactive).
    private(set) var endDate: Date?
    /// The instant the fade should begin (endDate − fade).
    private(set) var fadeStartDate: Date?
    /// The total scheduled duration, for progress display.
    private(set) var totalSeconds: Int = 0
    /// The configured fade length in seconds.
    private(set) var fadeSeconds: Double = 0
    /// Whether the engine has already been told to begin its fade.
    private(set) var fadeArmed: Bool = false

    var isActive: Bool { endDate != nil }

    /// Start a timer for `minutes` with a `fade`-second taper at the end.
    func start(minutes: Int, fade: Double, from now: Date = Date()) {
        let total = max(1, minutes) * 60
        totalSeconds = total
        fadeSeconds = max(0, min(Double(total), fade))
        endDate = now.addingTimeInterval(TimeInterval(total))
        fadeStartDate = now.addingTimeInterval(TimeInterval(Double(total) - fadeSeconds))
        fadeArmed = false
    }

    /// Extend the active timer by `minutes`.
    func extend(byMinutes minutes: Int) {
        guard let end = endDate else { return }
        let add = max(0, minutes) * 60
        totalSeconds += add
        let newEnd = end.addingTimeInterval(TimeInterval(add))
        endDate = newEnd
        fadeStartDate = newEnd.addingTimeInterval(-fadeSeconds)
        fadeArmed = false
    }

    func cancel() {
        endDate = nil
        fadeStartDate = nil
        totalSeconds = 0
        fadeArmed = false
    }

    /// Seconds remaining until the end (0 when finished/inactive).
    func remaining(at date: Date) -> Int {
        guard let end = endDate else { return 0 }
        return max(0, Int(end.timeIntervalSince(date).rounded(.up)))
    }

    /// 0…1 progress through the whole timer.
    func progress(at date: Date) -> Double {
        guard totalSeconds > 0 else { return 0 }
        let remainingFraction = Double(remaining(at: date)) / Double(totalSeconds)
        return min(1, max(0, 1 - remainingFraction))
    }

    /// Whether we are within the fade window now.
    func isFading(at date: Date) -> Bool {
        guard let fadeStart = fadeStartDate, isActive else { return false }
        return date >= fadeStart
    }

    /// Whether the timer has run out at `date`.
    func isFinished(at date: Date) -> Bool {
        guard let end = endDate else { return false }
        return date >= end
    }

    /// Mark the fade as armed so the engine ramp is only requested once.
    func markFadeArmed() { fadeArmed = true }
}
