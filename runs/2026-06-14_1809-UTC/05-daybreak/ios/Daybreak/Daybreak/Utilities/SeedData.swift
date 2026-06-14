import Foundation
import SwiftData

/// Seeds realistic sample routines + a rich run history on first launch, behind "didSeed".
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        guard !didSeed else { return }

        // 5 routines from templates (ignoring Pro gating for seed convenience).
        var routines: [Routine] = []
        for (i, template) in RoutineTemplates.all.enumerated() {
            let routine = template.makeRoutine(sortOrder: i)
            context.insert(routine)
            routines.append(routine)
        }

        seedRuns(context: context, routines: routines)

        try? context.save()
        didSeed = true
    }

    /// ~70 RoutineRun records spread across the last ~5 weeks so streaks/heatmap/charts are rich.
    private static func seedRuns(context: ModelContext, routines: [Routine]) {
        guard !routines.isEmpty else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Deterministic-ish pseudo-randomness without importing extra deps.
        var seed: UInt64 = 0x9E3779B97F4A7C15
        func next() -> Double {
            seed ^= seed << 13
            seed ^= seed >> 7
            seed ^= seed << 17
            return Double(seed % 1000) / 1000.0
        }

        var created = 0
        // Walk back 35 days; most days have 1-3 runs, with a few gaps for realistic streaks.
        for dayOffset in 0..<35 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // ~18% chance of a rest day (a gap).
            if next() < 0.18 { continue }

            let runsToday = 1 + Int(next() * 2.4) // 1...3
            for _ in 0..<runsToday {
                let routine = routines[Int(next() * Double(routines.count)) % routines.count]
                let total = max(1, routine.orderedSteps.count)

                // 70% fully complete, 18% near-complete (>=80%), rest abandoned.
                let roll = next()
                let completed: Int
                if roll < 0.70 {
                    completed = total
                } else if roll < 0.88 {
                    completed = max(1, Int(Double(total) * 0.8))
                } else {
                    completed = max(0, Int(Double(total) * 0.4))
                }

                // Start time somewhere during the day.
                let hour = routine.timeOfDay == .evening ? 19 + Int(next() * 3) : 6 + Int(next() * 4)
                let minute = Int(next() * 59)
                let date = calendar.date(bySettingHour: min(hour, 23), minute: minute, second: 0, of: day) ?? day

                // Duration roughly proportional to completed steps + a base.
                let baseSeconds = routine.totalSeconds
                let fraction = Double(completed) / Double(total)
                let duration = max(30, Int(Double(baseSeconds) * fraction) + completed * 20)

                let run = RoutineRun(date: date,
                                     routineName: routine.name,
                                     routineRef: routine,
                                     completedSteps: completed,
                                     totalSteps: total,
                                     durationSec: duration)
                context.insert(run)
                created += 1
            }
            if created >= 80 { break }
        }
    }

    /// Wipe all routines (cascading steps) and all run records.
    static func clearAll(context: ModelContext) {
        if let runs = try? context.fetch(FetchDescriptor<RoutineRun>()) {
            for r in runs { context.delete(r) }
        }
        if let routines = try? context.fetch(FetchDescriptor<Routine>()) {
            for r in routines { context.delete(r) }
        }
        try? context.save()
    }
}
