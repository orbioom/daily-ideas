import Foundation

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case low, moderate, high, athlete
    var id: String { rawValue }
    var label: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .athlete: return "Athlete"
        }
    }
    /// Extra ml added per day for activity.
    var bonusML: Double {
        switch self {
        case .low: return 0
        case .moderate: return 350
        case .high: return 700
        case .athlete: return 1100
        }
    }
}

enum Climate: String, Codable, CaseIterable, Identifiable {
    case temperate, warm, hot
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    /// Multiplier applied to the base goal.
    var multiplier: Double {
        switch self {
        case .temperate: return 1.0
        case .warm: return 1.08
        case .hot: return 1.18
        }
    }
}

enum BodyProfile: String, Codable, CaseIterable, Identifiable {
    case female, male, other
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    /// ml per kg of body weight baseline.
    var mlPerKg: Double {
        switch self {
        case .female: return 31
        case .male: return 35
        case .other: return 33
        }
    }
}

/// Pure hydration math — recommended goals plus daily/weekly rollups over logs.
struct HydrationEngine {
    let calendar: Calendar
    init(calendar: Calendar = .current) { self.calendar = calendar }

    // MARK: - Recommended goal

    /// Goal in ml: (ml-per-kg × weight) × climate multiplier + activity bonus.
    /// Clamped to a sane 1.2–6.0 L range.
    func recommendedGoalML(weightKg: Double, profile: BodyProfile, activity: ActivityLevel, climate: Climate) -> Double {
        let base = profile.mlPerKg * max(20, min(250, weightKg))
        let withClimate = base * climate.multiplier
        let total = withClimate + activity.bonusML
        return min(6000, max(1200, (total / 50).rounded() * 50))
    }

    // MARK: - Daily rollups

    func logs(_ logs: [DrinkLog], on day: Date) -> [DrinkLog] {
        logs.filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    func effectiveTotal(_ logs: [DrinkLog]) -> Double {
        logs.reduce(0) { $0 + $1.effectiveML }
    }

    func rawTotal(_ logs: [DrinkLog]) -> Double {
        logs.reduce(0) { $0 + $1.volumeML }
    }

    func caffeineTotal(_ logs: [DrinkLog]) -> Double {
        logs.reduce(0) { $0 + $1.caffeineMg }
    }

    func progress(_ logs: [DrinkLog], goalML: Double) -> Double {
        guard goalML > 0 else { return 0 }
        return effectiveTotal(logs) / goalML
    }

    // MARK: - Streak of goal-met days

    func goalStreak(_ all: [DrinkLog], goalML: Double, asOf today: Date = .now) -> Int {
        guard goalML > 0 else { return 0 }
        let grouped = Dictionary(grouping: all) { calendar.startOfDay(for: $0.date) }
        let metDays = Set(grouped.filter { effectiveTotal($0.value) >= goalML }.keys)
        guard !metDays.isEmpty else { return 0 }
        let start = calendar.startOfDay(for: today)
        var anchor: Date
        if metDays.contains(start) {
            anchor = start
        } else if let y = calendar.date(byAdding: .day, value: -1, to: start), metDays.contains(y) {
            anchor = y
        } else {
            return 0
        }
        var count = 0
        var cursor = anchor
        while metDays.contains(cursor) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return count
    }

    // MARK: - History series

    struct DayTotal: Identifiable {
        let id = UUID()
        let day: Date
        let effectiveML: Double
        let met: Bool
    }

    func dailyTotals(_ all: [DrinkLog], days span: Int, goalML: Double, asOf today: Date = .now) -> [DayTotal] {
        let start = calendar.startOfDay(for: today)
        var result: [DayTotal] = []
        for offset in stride(from: span - 1, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: start) else { continue }
            let dayLogs = all.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let eff = effectiveTotal(dayLogs)
            result.append(DayTotal(day: day, effectiveML: eff, met: goalML > 0 && eff >= goalML))
        }
        return result
    }

    func averageDaily(_ all: [DrinkLog], days span: Int, asOf today: Date = .now) -> Double {
        let totals = dailyTotals(all, days: span, goalML: 0, asOf: today)
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0) { $0 + $1.effectiveML } / Double(totals.count)
    }

    // MARK: - Sources breakdown

    struct SourceTotal: Identifiable {
        let id = UUID()
        let name: String
        let colorHex: UInt32
        let volumeML: Double
    }

    func sources(_ logs: [DrinkLog]) -> [SourceTotal] {
        var map: [String: (UInt32, Double)] = [:]
        for l in logs {
            let e = map[l.drinkName] ?? (l.drinkColorHex, 0)
            map[l.drinkName] = (l.drinkColorHex, e.1 + l.volumeML)
        }
        return map.map { SourceTotal(name: $0.key, colorHex: $0.value.0, volumeML: $0.value.1) }
            .sorted { $0.volumeML > $1.volumeML }
    }

    // MARK: - By weekday averages

    struct WeekdayAverage: Identifiable {
        let id = UUID()
        let weekday: Int     // 1…7
        let symbol: String
        let averageML: Double
    }

    func weekdayAverages(_ all: [DrinkLog]) -> [WeekdayAverage] {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var sums = Array(repeating: 0.0, count: 8)
        var dayCounts = Array(repeating: Set<Date>(), count: 8)
        for l in all {
            let wd = calendar.component(.weekday, from: l.date)
            sums[wd] += l.effectiveML
            dayCounts[wd].insert(calendar.startOfDay(for: l.date))
        }
        var result: [WeekdayAverage] = []
        for wd in 1...7 {
            let nDays = max(1, dayCounts[wd].count)
            result.append(WeekdayAverage(weekday: wd, symbol: symbols[wd - 1], averageML: sums[wd] / Double(nDays)))
        }
        return result
    }
}
