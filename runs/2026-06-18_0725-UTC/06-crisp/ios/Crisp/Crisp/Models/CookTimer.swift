import Foundation
import SwiftData

/// A live cooking timer. Persisted so timers survive backgrounding and relaunch —
/// remaining time is always recomputed from `endDate`, never from a ticking counter.
@Model
final class CookTimer {
    @Attribute(.unique) var id: UUID
    var label: String
    var foodId: String?
    var totalSeconds: Int
    var endDate: Date
    var startedAt: Date
    var isActive: Bool
    var createdAt: Date

    /// When paused, the seconds remaining are frozen here and `isActive` is false.
    var pausedRemaining: Int?

    init(
        id: UUID = UUID(),
        label: String,
        foodId: String? = nil,
        totalSeconds: Int,
        endDate: Date,
        startedAt: Date = .now,
        isActive: Bool = true,
        createdAt: Date = .now,
        pausedRemaining: Int? = nil
    ) {
        self.id = id
        self.label = label
        self.foodId = foodId
        self.totalSeconds = max(1, totalSeconds)
        self.endDate = endDate
        self.startedAt = startedAt
        self.isActive = isActive
        self.createdAt = createdAt
        self.pausedRemaining = pausedRemaining
    }

    /// Seconds left right now. Clamped to ≥ 0. Uses the frozen value when paused.
    func remainingSeconds(at now: Date = .now) -> Int {
        if !isActive, let paused = pausedRemaining {
            return max(0, paused)
        }
        return max(0, Int(endDate.timeIntervalSince(now).rounded()))
    }

    /// Fraction of the timer already elapsed, in 0...1. Guarded against zero total.
    func progress(at now: Date = .now) -> Double {
        let total = max(1, totalSeconds)
        let remaining = remainingSeconds(at: now)
        let elapsed = Double(total - remaining)
        return min(1, max(0, elapsed / Double(total)))
    }

    /// True once the timer has reached zero (and it was running).
    func isFinished(at now: Date = .now) -> Bool {
        isActive && remainingSeconds(at: now) <= 0
    }
}
