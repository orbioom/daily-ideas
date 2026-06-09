import Foundation

/// Pure pet-care math: ages, due-task bucketing, weight trends.
enum PetEngine {

    // MARK: - Age

    static func ageString(from birthday: Date?, now: Date = .now, calendar: Calendar = .current) -> String? {
        guard let birthday, birthday <= now else { return nil }
        let comps = calendar.dateComponents([.year, .month], from: birthday, to: now)
        let y = comps.year ?? 0, m = comps.month ?? 0
        if y == 0 && m == 0 { return "Under a month" }
        if y == 0 { return "\(m) mo" }
        if m == 0 { return "\(y) yr" }
        return "\(y) yr \(m) mo"
    }

    // MARK: - Task status

    enum Bucket: Int { case overdue, today, soon, later }

    struct DueTask: Identifiable {
        let id: PersistentIdentifier
        let task: CareTask
        let pet: Pet
        let due: Date
        let daysUntil: Int
        var bucket: Bucket {
            if daysUntil < 0 { return .overdue }
            if daysUntil == 0 { return .today }
            if daysUntil <= 3 { return .soon }
            return .later
        }
    }

    static func dueTasks(for pets: [Pet], now: Date = .now, calendar: Calendar = .current) -> [DueTask] {
        let today = calendar.startOfDay(for: now)
        var out: [DueTask] = []
        for pet in pets where !pet.isArchived {
            for task in pet.activeTasks {
                let due = calendar.startOfDay(for: task.nextDue)
                let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
                out.append(DueTask(id: task.persistentModelID, task: task, pet: pet,
                                   due: due, daysUntil: days))
            }
        }
        return out.sorted { $0.daysUntil < $1.daysUntil }
    }

    static func bucketLabel(_ b: Bucket) -> String {
        switch b {
        case .overdue: return "Overdue"
        case .today: return "Today"
        case .soon: return "Soon"
        case .later: return "Upcoming"
        }
    }

    static func dueLabel(_ days: Int) -> String {
        switch days {
        case ..<(-1): return "\(-days) days overdue"
        case -1: return "1 day overdue"
        case 0: return "Due today"
        case 1: return "Tomorrow"
        default: return "in \(days) days"
        }
    }

    // MARK: - Weight

    struct WeightPoint: Identifiable {
        let id: PersistentIdentifier
        let date: Date
        let kilograms: Double
    }

    static func weightSeries(for pet: Pet) -> [WeightPoint] {
        pet.weights.sorted { $0.date < $1.date }
            .map { WeightPoint(id: $0.persistentModelID, date: $0.date, kilograms: $0.kilograms) }
    }

    /// Change between the two most recent weights, in kilograms (signed).
    static func recentChangeKg(for pet: Pet) -> Double? {
        let sorted = pet.weights.sorted { $0.date > $1.date }
        guard sorted.count >= 2 else { return nil }
        return sorted[0].kilograms - sorted[1].kilograms
    }

    // MARK: - Aggregates

    static func nextDueCount(for pet: Pet, withinDays: Int = 0, now: Date = .now, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        return pet.activeTasks.filter { task in
            let due = calendar.startOfDay(for: task.nextDue)
            let days = calendar.dateComponents([.day], from: today, to: due).day ?? 0
            return days <= withinDays
        }.count
    }
}
