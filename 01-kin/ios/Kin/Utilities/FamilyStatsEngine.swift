import Foundation
import SwiftData

struct FamilyStats {
    let totalPeople: Int
    let livingCount: Int
    let deceasedCount: Int
    let uniqueLastNames: Int
    let oldestPerson: Person?
    let newestAddition: Person?
    let totalEvents: Int
    let generationsApprox: Int
}

struct FamilyStatsEngine {
    static func compute(people: [Person]) -> FamilyStats {
        let living = people.filter { !$0.isDeceased }
        let deceased = people.filter { $0.isDeceased }
        let lastNames = Set(people.map { $0.lastName }.filter { !$0.isEmpty })
        let totalEvents = people.reduce(0) { $0 + $1.lifeEvents.count }

        let oldest: Person? = people.compactMap { p -> (Person, Date)? in
            guard let b = p.birthDate else { return nil }
            return (p, b)
        }
        .min(by: { $0.1 < $1.1 })?.0

        let newest = people.max(by: { $0.createdAt < $1.createdAt })

        // rough generation count: depth of longest parent chain
        var maxDepth = 0
        func depth(of person: Person, visited: inout Set<UUID>) -> Int {
            if visited.contains(person.id) { return 0 }
            visited.insert(person.id)
            let parentDepths = person.parents.map { p -> Int in
                var v = visited
                return depth(of: p, visited: &v)
            }
            return 1 + (parentDepths.max() ?? 0)
        }
        for person in people {
            var visited = Set<UUID>()
            let d = depth(of: person, visited: &visited)
            if d > maxDepth { maxDepth = d }
        }

        return FamilyStats(
            totalPeople: people.count,
            livingCount: living.count,
            deceasedCount: deceased.count,
            uniqueLastNames: lastNames.count,
            oldestPerson: oldest,
            newestAddition: newest,
            totalEvents: totalEvents,
            generationsApprox: maxDepth
        )
    }
}
