import Foundation

/// Pure relationship logic: reach-out due dates, upcoming occasions, stats.
enum KithEngine {

    // MARK: - Reach-out cadence

    /// When the next reach-out is due. Based on last contact (or the date the
    /// person was added if never contacted). Nil when no cadence is set.
    static func nextReachOut(for person: Person, calendar: Calendar = .current) -> Date? {
        guard person.cadenceDays > 0 else { return nil }
        let base = person.lastContact ?? person.createdAt
        return calendar.date(byAdding: .day, value: person.cadenceDays, to: base)
    }

    static func daysSinceContact(for person: Person, now: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let last = person.lastContact else { return nil }
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: last),
                                       to: calendar.startOfDay(for: now)).day
    }

    enum Bucket: Int { case overdue, today, soon, later }

    struct ReachOut: Identifiable {
        let id: PersistentIdentifier
        let person: Person
        let due: Date
        let daysUntil: Int
        var bucket: Bucket {
            if daysUntil < 0 { return .overdue }
            if daysUntil == 0 { return .today }
            if daysUntil <= 3 { return .soon }
            return .later
        }
    }

    static func reachOuts(for people: [Person], soonWindow: Int = 3,
                          now: Date = .now, calendar: Calendar = .current) -> [ReachOut] {
        let today = calendar.startOfDay(for: now)
        return people.filter { !$0.isArchived }.compactMap { p in
            guard let due = nextReachOut(for: p, calendar: calendar) else { return nil }
            let dueDay = calendar.startOfDay(for: due)
            let days = calendar.dateComponents([.day], from: today, to: dueDay).day ?? 0
            return ReachOut(id: p.persistentModelID, person: p, due: dueDay, daysUntil: days)
        }
        .filter { $0.daysUntil <= soonWindow }
        .sorted { $0.daysUntil < $1.daysUntil }
    }

    static func dueLabel(_ days: Int) -> String {
        switch days {
        case ..<0: return "\(-days)d overdue"
        case 0: return "Due today"
        case 1: return "Tomorrow"
        default: return "in \(days)d"
        }
    }

    // MARK: - Important dates

    /// The next occurrence of an important date (rolls forward annually).
    static func nextOccurrence(of date: ImportantDate, now: Date = .now, calendar: Calendar = .current) -> Date {
        guard date.recursAnnually else { return date.date }
        let today = calendar.startOfDay(for: now)
        var comps = calendar.dateComponents([.month, .day], from: date.date)
        let thisYear = calendar.component(.year, from: today)
        comps.year = thisYear
        var next = calendar.date(from: comps) ?? date.date
        if calendar.startOfDay(for: next) < today {
            comps.year = thisYear + 1
            next = calendar.date(from: comps) ?? next
        }
        return next
    }

    struct Occasion: Identifiable {
        let id: PersistentIdentifier
        let date: ImportantDate
        let person: Person
        let occurrence: Date
        let daysUntil: Int
        /// Age/years turning, if the original year is known and meaningful.
        let turning: Int?
    }

    static func upcomingOccasions(for people: [Person], withinDays: Int = 30,
                                  now: Date = .now, calendar: Calendar = .current) -> [Occasion] {
        let today = calendar.startOfDay(for: now)
        var out: [Occasion] = []
        for person in people where !person.isArchived {
            for d in person.dates {
                let occ = nextOccurrence(of: d, now: now, calendar: calendar)
                let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: occ)).day ?? 0
                guard days >= 0, days <= withinDays else { continue }
                var turning: Int? = nil
                if d.recursAnnually {
                    let origYear = calendar.component(.year, from: d.date)
                    let occYear = calendar.component(.year, from: occ)
                    let years = occYear - origYear
                    if years > 0 && years < 130 { turning = years }
                }
                out.append(Occasion(id: d.persistentModelID, date: d, person: person,
                                    occurrence: occ, daysUntil: days, turning: turning))
            }
        }
        return out.sorted { $0.daysUntil < $1.daysUntil }
    }

    static func occasionLabel(_ days: Int) -> String {
        switch days {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "in \(days) days"
        }
    }

    // MARK: - Stats

    static func interactionsThisMonth(_ people: [Person], now: Date = .now, calendar: Calendar = .current) -> Int {
        people.flatMap { $0.interactions }
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    struct RelationCount: Identifiable {
        var id: String { relationship.rawValue }
        let relationship: Relationship
        let count: Int
    }

    static func byRelationship(_ people: [Person]) -> [RelationCount] {
        let active = people.filter { !$0.isArchived }
        let groups = Dictionary(grouping: active, by: { $0.relationship })
        return groups.map { RelationCount(relationship: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    struct MonthCount: Identifiable {
        let id = UUID()
        let month: Date
        let count: Int
    }

    static func interactionsByMonth(_ people: [Person], months: Int = 6,
                                    now: Date = .now, calendar: Calendar = .current) -> [MonthCount] {
        let all = people.flatMap { $0.interactions }
        let startOfThis = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return (0..<months).reversed().compactMap { offset in
            guard let m = calendar.date(byAdding: .month, value: -offset, to: startOfThis) else { return nil }
            let count = all.filter { calendar.isDate($0.date, equalTo: m, toGranularity: .month) }.count
            return MonthCount(month: m, count: count)
        }
    }

    /// People you've been out of touch with the longest (have a cadence, sorted).
    static func fallingOutOfTouch(_ people: [Person], now: Date = .now, calendar: Calendar = .current) -> [Person] {
        people.filter { !$0.isArchived }
            .sorted { a, b in
                let da = a.lastContact ?? a.createdAt
                let db = b.lastContact ?? b.createdAt
                return da < db
            }
    }
}
