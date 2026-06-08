import Foundation

enum RoundingRule: String, CaseIterable, Identifiable {
    case none, five = "5", fifteen = "15", thirty = "30"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "Exact"
        case .five: return "Nearest 5 min"
        case .fifteen: return "Nearest 15 min"
        case .thirty: return "Nearest 30 min"
        }
    }
    var minutes: Int {
        switch self {
        case .none: return 0
        case .five: return 5
        case .fifteen: return 15
        case .thirty: return 30
        }
    }
}

/// Pure time-tracking computations: durations, daily/weekly rollups, project &
/// client breakdowns, billable earnings, and reportable totals.
struct TimeEngine {
    let calendar: Calendar
    init(calendar: Calendar = .current) { self.calendar = calendar }

    // MARK: - Rounding

    /// Round seconds to the nearest rule increment (used in reports only).
    func rounded(_ seconds: TimeInterval, rule: RoundingRule) -> TimeInterval {
        guard rule.minutes > 0 else { return seconds }
        let inc = Double(rule.minutes * 60)
        return (seconds / inc).rounded() * inc
    }

    // MARK: - Running entry

    func running(_ entries: [TimeEntry]) -> TimeEntry? {
        entries.first { $0.isRunning }
    }

    // MARK: - Day grouping

    func entries(_ entries: [TimeEntry], on day: Date) -> [TimeEntry] {
        entries.filter { calendar.isDate($0.start, inSameDayAs: day) }
            .sorted { $0.start > $1.start }
    }

    func groupedByDay(_ entries: [TimeEntry]) -> [(day: Date, items: [TimeEntry])] {
        let dict = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.start) }
        return dict.map { (day: $0.key, items: $0.value.sorted { $0.start > $1.start }) }
            .sorted { $0.day > $1.day }
    }

    // MARK: - Totals

    func totalSeconds(_ entries: [TimeEntry], now: Date = .now) -> TimeInterval {
        entries.reduce(0) { $0 + $1.seconds(now: now) }
    }

    func totalEarnings(_ entries: [TimeEntry], now: Date = .now) -> Double {
        entries.reduce(0) { $0 + $1.earnings(now: now) }
    }

    // MARK: - Date ranges

    func weekInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 7 * 86400)
    }

    func monthInterval(containing date: Date) -> DateInterval {
        calendar.dateInterval(of: .month, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 30 * 86400)
    }

    func entries(_ entries: [TimeEntry], in interval: DateInterval) -> [TimeEntry] {
        entries.filter { interval.contains($0.start) }
    }

    // MARK: - Breakdowns

    struct ProjectTotal: Identifiable {
        let id = UUID()
        let projectName: String
        let colorHex: UInt32
        let seconds: TimeInterval
        let earnings: Double
    }

    func byProject(_ entries: [TimeEntry], now: Date = .now) -> [ProjectTotal] {
        var map: [String: (UInt32, TimeInterval, Double)] = [:]
        for e in entries {
            let name = e.project?.name ?? "No project"
            let color = e.project?.colorHex ?? 0x8B8FA3
            let existing = map[name] ?? (color, 0, 0)
            map[name] = (color, existing.1 + e.seconds(now: now), existing.2 + e.earnings(now: now))
        }
        return map.map { ProjectTotal(projectName: $0.key, colorHex: $0.value.0,
                                      seconds: $0.value.1, earnings: $0.value.2) }
            .sorted { $0.seconds > $1.seconds }
    }

    struct DaySeconds: Identifiable {
        let id = UUID()
        let day: Date
        let seconds: TimeInterval
    }

    func dailySeconds(_ entries: [TimeEntry], in interval: DateInterval, now: Date = .now) -> [DaySeconds] {
        var result: [DaySeconds] = []
        var cursor = calendar.startOfDay(for: interval.start)
        let last = interval.end
        while cursor < last {
            let dayLogs = entries.filter { calendar.isDate($0.start, inSameDayAs: cursor) }
            result.append(DaySeconds(day: cursor, seconds: totalSeconds(dayLogs, now: now)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return result
    }
}
