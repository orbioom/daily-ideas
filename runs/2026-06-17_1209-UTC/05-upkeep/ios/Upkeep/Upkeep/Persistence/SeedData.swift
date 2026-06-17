import Foundation
import SwiftData

/// Seeds the standard systems + starter checklist with realistic, varied history.
/// Idempotent: checks an existing-task count before doing anything.
enum SeedData {

    static func seedIfNeeded(context: ModelContext, didSeed: inout Bool) {
        if didSeed { return }
        let existingCount = (try? context.fetchCount(FetchDescriptor<MaintenanceTask>())) ?? 0
        if existingCount > 0 {
            didSeed = true
            return
        }
        seed(context: context)
        didSeed = true
    }

    /// Builds tasks with staggered lastDone dates (some overdue, some due soon,
    /// some fresh) plus ~30 completion logs with costs over the past year.
    static func seed(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        let systems = TaskFactory.ensureSystems(in: context)

        // Deterministic-ish offsets so the gauge / schedule / insights populate well.
        // Each blueprint gets a lastDone computed relative to its interval so that
        // the bucket distribution is realistic.
        var createdTasks: [MaintenanceTask] = []

        for (index, blueprint) in StarterTasks.blueprints.enumerated() {
            let intervalDays = approxIntervalDays(blueprint)
            // Cycle through fractions to spread tasks across buckets.
            let fraction: Double
            switch index % 5 {
            case 0: fraction = 1.30   // overdue
            case 1: fraction = 0.97   // due soon
            case 2: fraction = 0.30   // fresh
            case 3: fraction = 1.05   // just overdue
            default: fraction = 0.60  // mid-cycle
            }
            let daysAgo = Int(Double(intervalDays) * fraction)
            let lastDone = calendar.date(byAdding: .day, value: -daysAgo, to: now)

            let task = TaskFactory.makeTask(from: blueprint,
                                            lastDone: lastDone,
                                            systems: systems,
                                            context: context)
            createdTasks.append(task)
        }

        seedLogs(for: createdTasks, calendar: calendar, now: now, context: context)
    }

    /// ~30 completion logs across the past year, weighted to high-frequency tasks.
    private static func seedLogs(for tasks: [MaintenanceTask],
                                 calendar: Calendar,
                                 now: Date,
                                 context: ModelContext) {
        guard !tasks.isEmpty else { return }

        var logCount = 0
        let targetLogs = 32

        // Round-robin across tasks, placing historic completions over ~360 days.
        var taskIndex = 0
        var dayOffset = 350

        while logCount < targetLogs && dayOffset > 0 {
            let task = tasks[taskIndex % tasks.count]
            taskIndex += 1

            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            // Cost: use estimate with slight variation, or nil for no-cost chores.
            let cost: Double?
            if let est = task.estimatedCost, est > 0 {
                let jitter = Double((logCount % 5)) * 2.5
                cost = (est + jitter)
            } else {
                cost = nil
            }
            let minutes = task.estimatedMinutes > 0 ? task.estimatedMinutes : nil

            let log = CompletionLog(date: date,
                                    costActual: cost,
                                    minutesSpent: minutes,
                                    note: "")
            context.insert(log)
            log.task = task

            logCount += 1
            // Step backwards by a varying amount so months are unevenly populated.
            dayOffset -= (8 + (logCount % 4) * 3)
        }
    }

    private static func approxIntervalDays(_ blueprint: StarterTaskBlueprint) -> Int {
        switch blueprint.cadence {
        case .everyNDays: return max(1, blueprint.interval)
        case .everyNWeeks: return max(1, blueprint.interval) * 7
        case .everyNMonths: return max(1, blueprint.interval) * 30
        case .everyNYears: return max(1, blueprint.interval) * 365
        case .seasonal: return 180
        }
    }
}
