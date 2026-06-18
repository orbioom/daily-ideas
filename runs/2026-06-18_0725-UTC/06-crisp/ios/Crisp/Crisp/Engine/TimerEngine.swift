import Foundation
import SwiftData
import Observation

/// Manages the lifecycle of multiple concurrent `CookTimer` models.
/// Stateless w.r.t. ticking — all "remaining" math lives on `CookTimer` and is
/// derived from `endDate`, so timers are correct across backgrounding and relaunch.
@Observable
@MainActor
final class TimerEngine {

    /// Ids of timers we've already fired completion feedback for this session,
    /// so a relaunch / re-render doesn't double-buzz.
    private(set) var firedIds: Set<UUID> = []

    /// Starts a new timer for `seconds`, persisting it. Returns the created timer.
    @discardableResult
    func start(
        label: String,
        seconds: Int,
        foodId: String?,
        context: ModelContext,
        soundEnabled: Bool
    ) -> CookTimer {
        let total = max(1, seconds)
        let now = Date()
        let timer = CookTimer(
            label: label,
            foodId: foodId,
            totalSeconds: total,
            endDate: now.addingTimeInterval(TimeInterval(total)),
            startedAt: now,
            isActive: true
        )
        context.insert(timer)
        save(context)

        let id = timer.id
        let fire = timer.endDate
        Task {
            let ok = await NotificationManager.shared.ensureAuthorized()
            if ok {
                await NotificationManager.shared.schedule(
                    id: id, label: label, fireDate: fire, soundEnabled: soundEnabled
                )
            }
        }
        return timer
    }

    /// Pauses a running timer, freezing its remaining seconds.
    func pause(_ timer: CookTimer, context: ModelContext) {
        guard timer.isActive else { return }
        timer.pausedRemaining = timer.remainingSeconds()
        timer.isActive = false
        NotificationManager.shared.cancel(id: timer.id)
        save(context)
    }

    /// Resumes a paused timer from where it left off.
    func resume(_ timer: CookTimer, context: ModelContext, soundEnabled: Bool) {
        guard !timer.isActive else { return }
        let remaining = max(1, timer.pausedRemaining ?? timer.remainingSeconds())
        timer.endDate = Date().addingTimeInterval(TimeInterval(remaining))
        timer.isActive = true
        timer.pausedRemaining = nil
        firedIds.remove(timer.id)
        save(context)

        let id = timer.id
        let fire = timer.endDate
        let label = timer.label
        Task {
            let ok = await NotificationManager.shared.ensureAuthorized()
            if ok {
                await NotificationManager.shared.schedule(
                    id: id, label: label, fireDate: fire, soundEnabled: soundEnabled
                )
            }
        }
    }

    /// Adds (or removes, if negative) seconds to a running timer.
    func adjust(_ timer: CookTimer, by deltaSeconds: Int, context: ModelContext, soundEnabled: Bool) {
        if timer.isActive {
            let newRemaining = max(1, timer.remainingSeconds() + deltaSeconds)
            timer.endDate = Date().addingTimeInterval(TimeInterval(newRemaining))
            timer.totalSeconds = max(timer.totalSeconds, newRemaining)
            NotificationManager.shared.cancel(id: timer.id)
            let id = timer.id, fire = timer.endDate, label = timer.label
            Task {
                if await NotificationManager.shared.ensureAuthorized() {
                    await NotificationManager.shared.schedule(id: id, label: label, fireDate: fire, soundEnabled: soundEnabled)
                }
            }
        } else if let paused = timer.pausedRemaining {
            timer.pausedRemaining = max(1, paused + deltaSeconds)
        }
        firedIds.remove(timer.id)
        save(context)
    }

    /// Stops and deletes a timer, cancelling any pending notification.
    func stop(_ timer: CookTimer, context: ModelContext) {
        NotificationManager.shared.cancel(id: timer.id)
        firedIds.remove(timer.id)
        context.delete(timer)
        save(context)
    }

    /// Marks a finished timer as handled and records the completion feedback once.
    /// Returns true the first time it sees this timer finished (caller fires haptics).
    func registerCompletionIfNeeded(_ timer: CookTimer) -> Bool {
        guard timer.isFinished() else { return false }
        guard !firedIds.contains(timer.id) else { return false }
        firedIds.insert(timer.id)
        return true
    }

    /// Count of currently running (active, not finished) timers — for the free cap.
    func activeRunningCount(_ timers: [CookTimer]) -> Int {
        timers.filter { $0.isActive && !$0.isFinished() }.count
    }

    private func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // Non-fatal: SwiftData autosaves; surfacing here would only spam logs.
        }
    }
}
