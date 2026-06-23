import Foundation

/// Aggregates finished workouts into chart-ready series and headline metrics.
/// All computations guard against empty data and division by zero.
struct StatsEngine {
    /// A point for the weekly volume chart.
    struct VolumePoint: Identifiable {
        let id = UUID()
        let weekStart: Date
        let volumeKg: Double
    }

    /// A point for an exercise's estimated-1RM trend.
    struct OneRepMaxPoint: Identifiable {
        let id = UUID()
        let date: Date
        let valueKg: Double
    }

    /// Volume contribution per muscle group.
    struct MusclePoint: Identifiable {
        let id = UUID()
        let muscle: MuscleGroup
        let volumeKg: Double
    }

    let workouts: [Workout]

    /// Only finished workouts, newest first.
    var finished: [Workout] {
        workouts.filter { !$0.isActive }.sorted { $0.startedAt > $1.startedAt }
    }

    var totalWorkouts: Int { finished.count }

    var totalVolumeKg: Double {
        finished.reduce(0) { $0 + $1.totalVolume }
    }

    var totalSets: Int {
        finished.reduce(0) { $0 + $1.completedSets.count }
    }

    /// Current streak in weeks that contain at least one workout, counting back
    /// from the current week.
    var weekStreak: Int {
        let cal = Calendar.current
        let weeks = Set(finished.compactMap { weekStart(of: $0.startedAt, cal: cal) })
        guard !weeks.isEmpty else { return 0 }
        var streak = 0
        var cursor = weekStart(of: .now, cal: cal)
        while let c = cursor, weeks.contains(c) {
            streak += 1
            cursor = cal.date(byAdding: .weekOfYear, value: -1, to: c)
        }
        return streak
    }

    /// Weekly volume for the last `weeks` weeks (oldest → newest), zero-filled.
    func weeklyVolume(weeks: Int = 8) -> [VolumePoint] {
        let cal = Calendar.current
        guard let thisWeek = weekStart(of: .now, cal: cal) else { return [] }
        var buckets: [Date: Double] = [:]
        for w in finished {
            if let ws = weekStart(of: w.startedAt, cal: cal) {
                buckets[ws, default: 0] += w.totalVolume
            }
        }
        var points: [VolumePoint] = []
        for i in stride(from: weeks - 1, through: 0, by: -1) {
            if let ws = cal.date(byAdding: .weekOfYear, value: -i, to: thisWeek) {
                points.append(VolumePoint(weekStart: ws, volumeKg: buckets[ws] ?? 0))
            }
        }
        return points
    }

    /// Volume by muscle group over the last `days` days (descending).
    func volumeByMuscle(days: Int = 30) -> [MusclePoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        var buckets: [MuscleGroup: Double] = [:]
        for w in finished where w.startedAt >= cutoff {
            for s in w.completedSets where !s.isWarmup {
                if let muscle = s.exercise?.muscle {
                    buckets[muscle, default: 0] += s.volume
                }
            }
        }
        return buckets
            .map { MusclePoint(muscle: $0.key, volumeKg: $0.value) }
            .filter { $0.volumeKg > 0 }
            .sorted { $0.volumeKg > $1.volumeKg }
    }

    /// Best estimated-1RM per session date for a given exercise (oldest → newest).
    func oneRepMaxTrend(for exercise: Exercise) -> [OneRepMaxPoint] {
        var byDay: [Date: Double] = [:]
        let cal = Calendar.current
        for w in finished {
            let day = cal.startOfDay(for: w.startedAt)
            for s in w.sets(for: exercise) where !s.isWarmup {
                if let e1rm = s.estimatedOneRepMax {
                    byDay[day] = max(byDay[day] ?? 0, e1rm)
                }
            }
        }
        return byDay
            .map { OneRepMaxPoint(date: $0.key, valueKg: $0.value) }
            .sorted { $0.date < $1.date }
    }

    /// All-time best estimated 1RM for an exercise.
    func bestOneRepMax(for exercise: Exercise) -> Double? {
        let values = finished.flatMap { $0.sets(for: exercise) }
            .compactMap { $0.estimatedOneRepMax }
        return values.max()
    }

    /// All-time heaviest completed working set for an exercise.
    func bestWeight(for exercise: Exercise) -> Double? {
        let values = finished.flatMap { $0.sets(for: exercise) }
            .filter { !$0.isWarmup && $0.reps > 0 }
            .map { $0.weightKg }
        return values.max()
    }

    private func weekStart(of date: Date, cal: Calendar) -> Date? {
        cal.dateInterval(of: .weekOfYear, for: date)?.start
    }
}
