import Foundation

struct BeltEngine {

    // MARK: - Current State

    static func currentBelt(from records: [BeltRecord]) -> BeltRecord? {
        records.sorted { $0.awardedDate < $1.awardedDate }.last
    }

    // MARK: - Session Stats

    static func totalSessions(_ sessions: [TrainingSession]) -> Int {
        sessions.count
    }

    static func totalHours(_ sessions: [TrainingSession]) -> Int {
        sessions.reduce(0) { $0 + $1.durationMinutes } / 60
    }

    static func totalMinutes(_ sessions: [TrainingSession]) -> Int {
        sessions.reduce(0) { $0 + $1.durationMinutes }
    }

    static func streakDays(_ sessions: [TrainingSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let trainingDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var checkDay = today

        // Check if trained today or yesterday to start streak
        if !trainingDays.contains(checkDay) {
            checkDay = calendar.date(byAdding: .day, value: -1, to: checkDay) ?? checkDay
            if !trainingDays.contains(checkDay) {
                return 0
            }
        }

        while trainingDays.contains(checkDay) {
            streak += 1
            checkDay = calendar.date(byAdding: .day, value: -1, to: checkDay) ?? checkDay
        }

        return streak
    }

    static func sessionsThisMonth(_ sessions: [TrainingSession]) -> Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components) else { return 0 }
        return sessions.filter { $0.date >= startOfMonth }.count
    }

    static func sessionsThisWeek(_ sessions: [TrainingSession]) -> Int {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return 0 }
        return sessions.filter { $0.date >= startOfWeek }.count
    }

    // MARK: - Submission Stats

    static func submissionRatio(_ sessions: [TrainingSession]) -> Double {
        let got = sessions.reduce(0) { $0 + $1.submissionsGot }
        let tapped = sessions.reduce(0) { $0 + $1.tapOuts }
        let total = got + tapped
        guard total > 0 else { return 0 }
        return Double(got) / Double(total)
    }

    static func totalSubmissionsGot(_ sessions: [TrainingSession]) -> Int {
        sessions.reduce(0) { $0 + $1.submissionsGot }
    }

    static func totalTapOuts(_ sessions: [TrainingSession]) -> Int {
        sessions.reduce(0) { $0 + $1.tapOuts }
    }

    // MARK: - Belt Progress

    /// Estimated progress (0.0–1.0) toward next belt based on session count
    static func progressToNextBelt(currentBelt: BjjBelt, sessionCount: Int) -> Double {
        guard let nextBelt = currentBelt.next else { return 1.0 }
        let sessionsAtCurrent = currentBelt.estimatedSessions
        let sessionsAtNext = nextBelt.estimatedSessions
        let range = Double(sessionsAtNext - sessionsAtCurrent)
        guard range > 0 else { return 0 }
        let progress = Double(sessionCount - sessionsAtCurrent) / range
        return min(max(progress, 0), 1)
    }

    /// Estimated sessions remaining until next belt
    static func sessionsUntilNextBelt(currentBelt: BjjBelt, sessionCount: Int) -> Int {
        guard let nextBelt = currentBelt.next else { return 0 }
        let remaining = nextBelt.estimatedSessions - sessionCount
        return max(remaining, 0)
    }

    // MARK: - Monthly Breakdown

    static func sessionsByMonth(_ sessions: [TrainingSession]) -> [(String, [TrainingSession])] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var grouped: [(Date, [TrainingSession])] = []
        var seen: [String: Int] = [:]

        for session in sessions.sorted(by: { $0.date > $1.date }) {
            let comps = calendar.dateComponents([.year, .month], from: session.date)
            guard let start = calendar.date(from: comps) else { continue }
            let key = formatter.string(from: start)
            if let idx = seen[key] {
                grouped[idx].1.append(session)
            } else {
                seen[key] = grouped.count
                grouped.append((start, [session]))
            }
        }

        return grouped.map { (formatter.string(from: $0.0), $0.1) }
    }

    // MARK: - Competition Stats

    static func totalWins(_ competitions: [Competition]) -> Int {
        competitions.reduce(0) { $0 + $1.wins }
    }

    static func totalLosses(_ competitions: [Competition]) -> Int {
        competitions.reduce(0) { $0 + $1.losses }
    }

    static func goldMedals(_ competitions: [Competition]) -> Int {
        competitions.filter { $0.medal == 3 }.count
    }

    static func silverMedals(_ competitions: [Competition]) -> Int {
        competitions.filter { $0.medal == 2 }.count
    }

    static func bronzeMedals(_ competitions: [Competition]) -> Int {
        competitions.filter { $0.medal == 1 }.count
    }
}
