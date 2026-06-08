import Foundation

struct SessionStats {
    let totalMinutes: Double
    let sessionCount: Int
    let streakDays: Int
    let todayMinutes: Double
    let last14: [DayBar]
    let favoritePattern: String?

    struct DayBar: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Double
    }

    static func make(from sessions: [BreathSession], calendar: Calendar = .current, now: Date = .now) -> SessionStats {
        let totalMin = sessions.reduce(0) { $0 + $1.minutes }
        let today = calendar.startOfDay(for: now)
        let todayMin = sessions.filter { calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.minutes }

        let daysWith = Set(sessions.map { calendar.startOfDay(for: $0.date) })
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
            let mins = sessions.filter { calendar.isDate($0.date, inSameDayAs: d) }
                .reduce(0) { $0 + $1.minutes }
            bars.append(DayBar(date: d, minutes: mins))
        }

        let counts = Dictionary(grouping: sessions, by: { $0.patternName }).mapValues { $0.count }
        let favorite = counts.max { $0.value < $1.value }?.key

        return SessionStats(totalMinutes: totalMin,
                            sessionCount: sessions.count,
                            streakDays: streak,
                            todayMinutes: todayMin,
                            last14: bars,
                            favoritePattern: favorite)
    }
}
