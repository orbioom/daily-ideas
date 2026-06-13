import Foundation
import SwiftData

enum SeedData {
    /// Give a brand-new runner a tiny bit of history so the app feels alive and
    /// the plan starts at session three of week one.
    static func seedStarter(_ context: ModelContext, planID: String) {
        let plan = PlanLibrary.plan(id: planID)
        guard let week1 = plan.weeks.first else { return }
        let workout = week1.sessions.first ?? Workout(segments: [])
        for (i, daysAgo) in [(0, 5), (1, 3)] {
            let log = RunLog(
                date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) ?? .now,
                planID: plan.id, planName: plan.name, weekNumber: 1, sessionIndex: i,
                title: "Week 1 · Run \(i + 1)",
                plannedSeconds: workout.totalSeconds,
                activeSeconds: workout.totalSeconds,
                distanceMeters: 2600 + Double(i) * 120,
                rating: 4 - i,
                note: i == 0 ? "First one done. Legs felt heavy but I finished." : "")
            context.insert(log)
        }
        try? context.save()
    }
}
