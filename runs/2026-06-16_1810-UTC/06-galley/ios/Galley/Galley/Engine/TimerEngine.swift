import Foundation
import SwiftData
import SwiftUI

/// Observable coordinator that watches the set of KitchenTimers and fires an
/// in-app completion alert + optional haptic when one reaches zero.
///
/// Timers themselves are wall-clock based on the model (`startedAt` +
/// `remainingWhenPaused`), so this engine holds no countdown state — it only
/// detects the transition to zero and surfaces the finished timer's id/label.
@Observable
final class TimerEngine {

    /// The id + label of the most recently finished timer awaiting acknowledgement.
    var firedTimerID: UUID?
    var firedTimerLabel: String = ""
    var showingFiredAlert: Bool = false

    /// Ids we've already fired for, to avoid duplicate alerts.
    private var firedIDs: Set<UUID> = []

    /// Inspect the current timers and fire for any that just hit zero.
    /// Called from the live TimelineView tick.
    @MainActor
    func evaluate(timers: [KitchenTimer], at date: Date, context: ModelContext) {
        for timer in timers where timer.isRunning {
            if timer.remaining(at: date) <= 0 {
                // Stop the timer model.
                timer.isRunning = false
                timer.startedAt = nil
                timer.remainingWhenPaused = 0

                if !firedIDs.contains(timer.id) {
                    firedIDs.insert(timer.id)
                    firedTimerID = timer.id
                    firedTimerLabel = timer.label
                    showingFiredAlert = true
                    Haptics.success()
                }
            }
        }
        try? context.save()
    }

    /// Start (or resume) a timer.
    @MainActor
    func start(_ timer: KitchenTimer, context: ModelContext) {
        guard !timer.isRunning else { return }
        // If it had finished/zeroed, reset to full before starting.
        if timer.remainingWhenPaused <= 0 {
            timer.remainingWhenPaused = timer.totalSeconds
        }
        timer.startedAt = .now
        timer.isRunning = true
        firedIDs.remove(timer.id)
        try? context.save()
    }

    /// Pause a running timer, banking the remaining seconds.
    @MainActor
    func pause(_ timer: KitchenTimer, context: ModelContext) {
        guard timer.isRunning else { return }
        timer.remainingWhenPaused = timer.remaining()
        timer.isRunning = false
        timer.startedAt = nil
        try? context.save()
    }

    /// Reset to full duration, stopped.
    @MainActor
    func reset(_ timer: KitchenTimer, context: ModelContext) {
        timer.isRunning = false
        timer.startedAt = nil
        timer.remainingWhenPaused = timer.totalSeconds
        firedIDs.remove(timer.id)
        try? context.save()
    }

    /// Acknowledge / dismiss the fired alert.
    func acknowledge() {
        showingFiredAlert = false
        firedTimerID = nil
        firedTimerLabel = ""
    }
}
