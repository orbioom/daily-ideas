import Foundation
import SwiftData

/// Per-exercise progress: where the user currently sits on the ladder, their
/// best test result, and when they last tested. Created lazily, one per exercise.
@Model
final class ExerciseProgress {
    @Attribute(.unique) var exerciseID: String
    var currentLevel: Int
    /// Best test result — reps or seconds depending on the exercise unit.
    var bestResult: Int
    var lastTested: Date?

    init(exerciseID: String, currentLevel: Int = 0, bestResult: Int = 0, lastTested: Date? = nil) {
        self.exerciseID = exerciseID
        self.currentLevel = currentLevel
        self.bestResult = bestResult
        self.lastTested = lastTested
    }
}

/// A completed guided session: one exercise, one level, per-set results.
@Model
final class WorkoutLog {
    var date: Date
    var exerciseID: String
    var levelIndex: Int
    /// Reps (or seconds) achieved per set, in order.
    var setResults: [Int]
    var note: String

    init(date: Date = .now, exerciseID: String, levelIndex: Int,
         setResults: [Int], note: String = "") {
        self.date = date
        self.exerciseID = exerciseID
        self.levelIndex = levelIndex
        self.setResults = setResults
        self.note = note
    }

    /// Total reps or seconds across all sets.
    var totalVolume: Int { setResults.reduce(0, +) }

    /// Whether every set met the given per-set target.
    func hitTarget(_ target: Int) -> Bool {
        guard !setResults.isEmpty else { return false }
        return setResults.allSatisfy { $0 >= target }
    }
}

// MARK: - Aggregate stats

/// One point in a per-exercise volume series.
struct VolumePoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Int
}

/// One bar in the sessions-per-week series.
struct WeekCount: Identifiable {
    let id = UUID()
    let weekStart: Date
    let count: Int
}

/// Aggregates over logged workouts: streaks, totals, and series for charts.
struct TrainingStats {
    let totalSessions: Int
    let totalReps: Int
    let currentStreak: Int
    let longestStreak: Int
    let levelsClimbed: Int

    static func from(_ logs: [WorkoutLog], progress: [ExerciseProgress]) -> TrainingStats {
        let totalReps = logs.reduce(0) { $0 + $1.totalVolume }
        let levelsClimbed = progress.reduce(0) { $0 + max(0, $1.currentLevel) }

        let cal = Calendar.current
        let days = Set(logs.map { cal.startOfDay(for: $0.date) }).sorted()
        var longest = 0, run = 0
        var prev: Date?
        for d in days {
            if let p = prev, cal.dateComponents([.day], from: p, to: d).day == 1 { run += 1 }
            else { run = 1 }
            longest = max(longest, run)
            prev = d
        }
        var current = 0
        if let last = days.last {
            let gap = cal.dateComponents([.day], from: last, to: cal.startOfDay(for: .now)).day ?? 99
            if gap <= 1 {
                current = 1
                var cursor = last
                while let p = cal.date(byAdding: .day, value: -1, to: cursor),
                      days.contains(p) { current += 1; cursor = p }
            }
        }

        return TrainingStats(
            totalSessions: logs.count,
            totalReps: totalReps,
            currentStreak: current,
            longestStreak: longest,
            levelsClimbed: levelsClimbed)
    }

    /// Volume-over-time for one exercise (most recent 20 sessions, oldest first).
    static func volumeSeries(_ logs: [WorkoutLog], exerciseID: String) -> [VolumePoint] {
        logs.filter { $0.exerciseID == exerciseID }
            .sorted { $0.date < $1.date }
            .suffix(20)
            .map { VolumePoint(date: $0.date, volume: $0.totalVolume) }
    }

    /// Session counts grouped by ISO week start (most recent 8 weeks).
    static func sessionsPerWeek(_ logs: [WorkoutLog]) -> [WeekCount] {
        guard !logs.isEmpty else { return [] }
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for log in logs {
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: log.date)
            if let start = cal.date(from: comps) {
                buckets[start, default: 0] += 1
            }
        }
        return buckets.keys.sorted()
            .suffix(8)
            .map { WeekCount(weekStart: $0, count: buckets[$0] ?? 0) }
    }
}
