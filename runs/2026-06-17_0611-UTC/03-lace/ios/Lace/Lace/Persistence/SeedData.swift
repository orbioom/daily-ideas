import Foundation
import SwiftData

/// Seeds a realistic in-progress Couch-to-5K enrollment with several weeks of
/// completed sessions on first launch, so History, charts and the streak have
/// real data. Idempotent: checks for an existing ActivePlan first.
enum SeedData {

    static func seedIfNeeded(_ context: ModelContext) {
        let descriptor = FetchDescriptor<ActivePlan>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        // Only seed if there is also no completed history (defensive).
        let doneDescriptor = FetchDescriptor<CompletedSession>()
        let done = (try? context.fetch(doneDescriptor)) ?? []
        guard done.isEmpty else { return }

        let cal = Calendar.current
        let now = Date()
        let plan = BuiltInPlans.couchTo5K

        // Enroll on Couch-to-5K, started ~24 days ago, currently into week 4.
        let start = cal.date(byAdding: .day, value: -24, to: now) ?? now
        let active = ActivePlan(planId: plan.id, startDate: start, currentWeek: 4, currentSessionIndex: 0)
        context.insert(active)

        // Completed sessions: weeks 1–3 fully done, plus a varied recent cadence
        // that yields a believable streak. (week, sessionIndex, daysAgo, felt).
        let plan2 = plan
        let log: [(week: Int, index: Int, daysAgo: Int, felt: Int)] = [
            (1, 0, 23, 3), (1, 1, 21, 4), (1, 2, 19, 4),
            (2, 0, 16, 3), (2, 1, 14, 4), (2, 2, 12, 5),
            (3, 0, 9, 4),  (3, 1, 7, 4),  (3, 2, 5, 3),
            (4, 0, 2, 4),  (4, 1, 1, 5)
        ]

        for entry in log {
            guard let session = plan2.session(week: entry.week, index: entry.index) else { continue }
            guard let date = cal.date(byAdding: .day, value: -entry.daysAgo, to: now) else { continue }
            // Distance estimate: ~10 km/h while running, walking distance ignored for the note.
            let approxMeters = Double(session.runSeconds) / 3600.0 * 10_000.0
            let completed = CompletedSession(
                date: date,
                planId: plan2.id,
                week: entry.week,
                sessionIndex: entry.index,
                durationSeconds: session.totalSeconds,
                runSeconds: session.runSeconds,
                feltRating: entry.felt,
                distanceMeters: approxMeters > 0 ? approxMeters : nil
            )
            context.insert(completed)
        }

        try? context.save()
    }
}
