import Foundation
import SwiftData

/// Helpers for managing the single `ActivePlan` enrollment and recording
/// completed sessions. Centralises the SwiftData mutations so views stay thin.
enum Enrollment {

    /// Replace any existing enrollment with a fresh one for `plan`.
    static func enroll(in plan: TrainingPlan, context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<ActivePlan>())) ?? []
        for e in existing { context.delete(e) }
        let active = ActivePlan(planId: plan.id, startDate: Date(), currentWeek: 1, currentSessionIndex: 0)
        context.insert(active)
        try? context.save()
    }

    /// The current enrollment, if any.
    static func current(context: ModelContext) -> ActivePlan? {
        (try? context.fetch(FetchDescriptor<ActivePlan>()))?.first
    }

    /// Record a finished session and advance the enrollment pointer if the
    /// completed session was the user's current one. Guards all index math.
    static func recordCompletion(plan: TrainingPlan,
                                 week: Int,
                                 sessionIndex: Int,
                                 durationSeconds: Int,
                                 runSeconds: Int,
                                 feltRating: Int?,
                                 distanceMeters: Double?,
                                 context: ModelContext) {
        let record = CompletedSession(
            planId: plan.id,
            week: week,
            sessionIndex: sessionIndex,
            durationSeconds: durationSeconds,
            runSeconds: runSeconds,
            feltRating: feltRating,
            distanceMeters: distanceMeters
        )
        context.insert(record)

        if let active = current(context: context),
           active.planId == plan.id,
           active.currentWeek == week,
           active.currentSessionIndex == sessionIndex {
            advance(active, in: plan)
        }
        try? context.save()
    }

    /// Move the pointer to the next session, rolling over weeks and clamping at
    /// the end of the plan.
    private static func advance(_ active: ActivePlan, in plan: TrainingPlan) {
        guard let weekObj = plan.weeks.first(where: { $0.weekNumber == active.currentWeek }) else { return }
        let nextIndex = active.currentSessionIndex + 1
        if nextIndex < weekObj.sessions.count {
            active.currentSessionIndex = nextIndex
        } else if let nextWeek = plan.weeks.first(where: { $0.weekNumber == active.currentWeek + 1 }) {
            active.currentWeek = nextWeek.weekNumber
            active.currentSessionIndex = 0
        }
        // Otherwise the plan is complete — leave the pointer on the final session.
    }
}
