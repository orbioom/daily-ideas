import Foundation

struct InsightsEngine {

    static func weeklyTotal(for week: Date, entries: [EmissionEntry]) -> Double {
        let range = weekRange(for: week)
        return entries
            .filter { range.contains($0.date) }
            .reduce(0) { $0 + $1.co2eKg }
    }

    static func last8WeeksTotals(entries: [EmissionEntry]) -> [(weekStart: Date, kg: Double)] {
        let calendar = Calendar.current
        let now = Date()
        return (0..<8).map { offset -> (weekStart: Date, kg: Double) in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: startOfWeek(for: now)) else {
                return (now, 0)
            }
            let total = weeklyTotal(for: weekStart, entries: entries)
            return (weekStart, total)
        }.reversed()
    }

    static func categoryBreakdown(entries: [EmissionEntry], in dateRange: ClosedRange<Date>) -> [(EmissionCategory, Double)] {
        let filtered = entries.filter { dateRange.contains($0.date) }
        return EmissionCategory.allCases.compactMap { category -> (EmissionCategory, Double)? in
            let total = filtered
                .filter { $0.category == category }
                .reduce(0) { $0 + $1.co2eKg }
            guard total > 0 else { return nil }
            return (category, total)
        }.sorted { $0.1 > $1.1 }
    }

    static func currentStreakDaysUnder(goalKg: Double, entries: [EmissionEntry]) -> Int {
        let calendar = Calendar.current
        let dailyGoal = goalKg / 7.0
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // Walk backwards day by day
        for _ in 0..<365 {
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: checkDate) ?? checkDate
            let dayRange = checkDate..<endOfDay
            let dayEntries = entries.filter { dayRange.contains($0.date) }

            // Only count days that have at least one entry
            guard !dayEntries.isEmpty else { break }

            let dayTotal = dayEntries.reduce(0) { $0 + $1.co2eKg }
            if dayTotal <= dailyGoal {
                streak += 1
            } else {
                break
            }

            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    static func totalLogged(entries: [EmissionEntry]) -> Double {
        entries.reduce(0) { $0 + $1.co2eKg }
    }

    static func bestWeekKg(entries: [EmissionEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        let weeks = last8WeeksTotals(entries: entries)
        let nonZeroWeeks = weeks.filter { $0.kg > 0 }
        return nonZeroWeeks.min(by: { $0.kg < $1.kg })?.kg ?? 0
    }

    static func co2eSavedVsWorldAvg(entries: [EmissionEntry]) -> Double {
        let weeks = last8WeeksTotals(entries: entries)
        let userAvg = weeks.isEmpty ? 0 : weeks.map(\.kg).reduce(0, +) / Double(weeks.count)
        let saved = (EmissionsEngine.worldAverageWeeklyKg - userAvg) * Double(weeks.count)
        return max(0, saved)
    }

    // MARK: - Private helpers

    private static func startOfWeek(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    private static func weekRange(for date: Date) -> ClosedRange<Date> {
        let start = startOfWeek(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? start
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return start...endOfDay
    }
}
