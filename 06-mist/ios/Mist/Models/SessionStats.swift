import Foundation

struct SessionStats {
    let sessions: [TherapySession]

    var totalSessions: Int { sessions.count }

    var totalMinutes: Int {
        sessions.map(\.durationSeconds).reduce(0, +) / 60
    }

    var currentStreak: Int {
        var streak = 0
        let cal = Calendar.current
        var checkDate = cal.startOfDay(for: Date())
        let sorted = sessions.sorted { $0.date > $1.date }
        var idx = 0
        while idx < sorted.count {
            let sessionDay = cal.startOfDay(for: sorted[idx].date)
            if sessionDay == checkDate {
                streak += 1
                checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                while idx < sorted.count && cal.startOfDay(for: sorted[idx].date) == sessionDay {
                    idx += 1
                }
            } else if sessionDay < checkDate {
                break
            } else {
                idx += 1
            }
        }
        return streak
    }

    var longestStreak: Int {
        guard !sessions.isEmpty else { return 0 }
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0.date) }).sorted()
        var best = 1
        var current = 1
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i-1], to: days[i]).day ?? 0
            if diff == 1 { current += 1; best = max(best, current) }
            else { current = 1 }
        }
        return best
    }

    var averageRating: Double {
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.map(\.rating).reduce(0, +)) / Double(sessions.count)
    }

    var personalBestDuration: Int {
        sessions.map(\.durationSeconds).max() ?? 0
    }

    var coldestSession: Double {
        sessions.filter { !$0.type.isHot }.map(\.temperatureCelsius).min() ?? 0
    }

    var hottest: Double {
        sessions.filter { $0.type.isHot }.map(\.temperatureCelsius).max() ?? 0
    }

    func weeklyMinutes(weeks: Int = 8) -> [(week: String, minutes: Int)] {
        let cal = Calendar.current
        let now = Date()
        return (0..<weeks).reversed().map { offset in
            let weekStart = cal.date(byAdding: .weekOfYear, value: -offset, to: cal.startOfDay(for: now))!
            let weekEnd = cal.date(byAdding: .day, value: 7, to: weekStart)!
            let minutes = sessions.filter { $0.date >= weekStart && $0.date < weekEnd }
                .map(\.durationSeconds).reduce(0, +) / 60
            let fmt = DateFormatter()
            fmt.dateFormat = "MM/dd"
            return (week: fmt.string(from: weekStart), minutes: minutes)
        }
    }

    func typeBreakdown() -> [(type: TherapyType, count: Int)] {
        var counts: [TherapyType: Int] = [:]
        for s in sessions { counts[s.type, default: 0] += 1 }
        return TherapyType.allCases.compactMap { t in
            guard let c = counts[t], c > 0 else { return nil }
            return (type: t, count: c)
        }
    }
}
