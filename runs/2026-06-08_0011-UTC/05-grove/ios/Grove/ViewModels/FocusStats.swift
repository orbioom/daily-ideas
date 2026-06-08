import Foundation

struct FocusStats {
    let totalMinutes: Double
    let todayMinutes: Double
    let treesPlanted: Int          // successful sessions
    let withered: Int
    let streakDays: Int
    let successRate: Double
    let last14: [DayBar]
    let byTag: [TagSlice]

    struct DayBar: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Double
    }
    struct TagSlice: Identifiable {
        let id = UUID()
        let name: String
        let minutes: Double
    }

    static func make(from sessions: [FocusSession], calendar: Calendar = .current, now: Date = .now) -> FocusStats {
        let successful = sessions.filter { $0.success }
        let totalMin = successful.reduce(0) { $0 + $1.minutes }
        let today = calendar.startOfDay(for: now)
        let todayMin = successful.filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.minutes }

        let daysWith = Set(successful.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var day = today
        if !daysWith.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while daysWith.contains(day) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        var bars: [DayBar] = []
        for offset in stride(from: 13, through: 0, by: -1) {
            guard let d = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let mins = successful.filter { calendar.isDate($0.date, inSameDayAs: d) }
                .reduce(0) { $0 + $1.minutes }
            bars.append(DayBar(date: d, minutes: mins))
        }

        let grouped = Dictionary(grouping: successful, by: { $0.tagName })
        let slices = grouped.map { TagSlice(name: $0.key, minutes: $0.value.reduce(0) { $0 + $1.minutes }) }
            .sorted { $0.minutes > $1.minutes }

        let total = sessions.count
        let rate = total > 0 ? Double(successful.count) / Double(total) : 0

        return FocusStats(totalMinutes: totalMin, todayMinutes: todayMin,
                          treesPlanted: successful.count, withered: sessions.count - successful.count,
                          streakDays: streak, successRate: rate, last14: bars, byTag: slices)
    }
}
