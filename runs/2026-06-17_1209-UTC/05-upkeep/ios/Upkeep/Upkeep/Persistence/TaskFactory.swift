import Foundation
import SwiftData

/// Builds SwiftData objects from blueprints and links them to their systems.
enum TaskFactory {

    /// Ensure all standard systems exist, returning a name → system map.
    @discardableResult
    static func ensureSystems(in context: ModelContext) -> [String: HomeSystem] {
        let existing = (try? context.fetch(FetchDescriptor<HomeSystem>())) ?? []
        var map: [String: HomeSystem] = [:]
        for system in existing { map[system.name] = system }

        for (index, entry) in SystemCatalog.all.enumerated() where map[entry.name] == nil {
            let system = HomeSystem(name: entry.name, symbolName: entry.symbol, order: index)
            context.insert(system)
            map[entry.name] = system
        }
        return map
    }

    /// Create a task from a blueprint, attaching it to the matching system.
    @discardableResult
    static func makeTask(from blueprint: StarterTaskBlueprint,
                         lastDone: Date?,
                         systems: [String: HomeSystem],
                         context: ModelContext) -> MaintenanceTask {
        let task = MaintenanceTask(title: blueprint.title,
                                   systemName: blueprint.systemName,
                                   cadenceType: blueprint.cadence,
                                   intervalCount: blueprint.interval,
                                   season: blueprint.season,
                                   lastDone: lastDone,
                                   estimatedMinutes: blueprint.minutes,
                                   estimatedCost: blueprint.cost,
                                   priority: blueprint.priority,
                                   notes: blueprint.notes)
        context.insert(task)
        task.system = systems[blueprint.systemName]
        return task
    }

    /// Titles already present, to avoid adding duplicate starter tasks.
    static func existingTaskTitles(in context: ModelContext) -> Set<String> {
        let tasks = (try? context.fetch(FetchDescriptor<MaintenanceTask>())) ?? []
        return Set(tasks.map { $0.title })
    }

    /// Add the starter checklist, skipping any titles that already exist.
    /// Returns the number of tasks actually added.
    @discardableResult
    static func addStarterChecklist(into context: ModelContext) -> Int {
        let systems = ensureSystems(in: context)
        let present = existingTaskTitles(in: context)
        var added = 0
        for blueprint in StarterTasks.blueprints where !present.contains(blueprint.title) {
            _ = makeTask(from: blueprint, lastDone: nil, systems: systems, context: context)
            added += 1
        }
        return added
    }
}
