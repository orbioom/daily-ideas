import Foundation
import SwiftUI

/// Wall-clock rest timer. Anchored to an end `Date` so it stays correct across
/// backgrounding and relaunch (combined with a TimelineView in the UI).
@Observable
@MainActor
final class RestTimerModel {
    private(set) var endDate: Date?
    private(set) var totalSeconds: Int = 0

    var isRunning: Bool {
        guard let end = endDate else { return false }
        return end > .now
    }

    /// Seconds remaining, never negative.
    func remaining(at date: Date = .now) -> TimeInterval {
        guard let end = endDate else { return 0 }
        return max(0, end.timeIntervalSince(date))
    }

    /// Progress 0...1 elapsed.
    func progress(at date: Date = .now) -> Double {
        guard totalSeconds > 0 else { return 0 }
        let remain = remaining(at: date)
        return min(1, max(0, 1 - remain / Double(totalSeconds)))
    }

    func start(seconds: Int) {
        let clamped = max(1, seconds)
        totalSeconds = clamped
        endDate = Date.now.addingTimeInterval(TimeInterval(clamped))
    }

    func add(seconds: Int) {
        guard let end = endDate else {
            start(seconds: max(1, seconds))
            return
        }
        let newEnd = end.addingTimeInterval(TimeInterval(seconds))
        // Don't allow negative remaining; keep at least 1s if subtracting.
        if newEnd <= .now {
            endDate = Date.now.addingTimeInterval(1)
        } else {
            endDate = newEnd
        }
        totalSeconds = max(totalSeconds + seconds, 1)
    }

    func stop() {
        endDate = nil
        totalSeconds = 0
    }
}
