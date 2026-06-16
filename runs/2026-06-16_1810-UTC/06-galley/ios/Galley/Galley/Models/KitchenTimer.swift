import Foundation
import SwiftData

@Model
final class KitchenTimer {
    @Attribute(.unique) var id: UUID
    var label: String
    var totalSeconds: Int
    /// Wall-clock anchor: when the timer was (re)started. nil when paused/idle.
    var startedAt: Date?
    var isRunning: Bool
    /// Seconds remaining when paused (or initially the full duration).
    var remainingWhenPaused: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        totalSeconds: Int,
        startedAt: Date? = nil,
        isRunning: Bool = false,
        remainingWhenPaused: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.label = label
        self.totalSeconds = max(1, totalSeconds)
        self.startedAt = startedAt
        self.isRunning = isRunning
        self.remainingWhenPaused = remainingWhenPaused ?? max(1, totalSeconds)
        self.createdAt = createdAt
    }

    /// Remaining seconds at `date`, computed from the wall clock (drift-free, relaunch-safe).
    func remaining(at date: Date = .now) -> Int {
        if isRunning, let startedAt {
            let elapsed = date.timeIntervalSince(startedAt)
            let left = Double(remainingWhenPaused) - elapsed
            return max(0, Int(left.rounded(.up)))
        }
        return max(0, remainingWhenPaused)
    }

    /// Whether the timer has reached zero while running.
    func isFinished(at date: Date = .now) -> Bool {
        isRunning && remaining(at: date) <= 0
    }
}
