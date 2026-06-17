import Foundation

/// A time window over which stats are computed.
enum StatsPeriod: String, CaseIterable, Identifiable {
    case month = "30 days"
    case quarter = "90 days"
    case year = "Year"
    case all = "All time"
    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .all: return nil
        }
    }
}

/// One stroke's share of total distance.
struct StrokeSlice: Identifiable {
    let id = UUID()
    let stroke: Stroke
    let distanceMeters: Double
}

/// A point in the distance-over-time bar chart.
struct DistancePoint: Identifiable {
    let id = UUID()
    let weekStart: Date
    let distanceMeters: Double
}

/// A point in the pace-per-100 trend.
struct PacePoint: Identifiable {
    let id = UUID()
    let date: Date
    let secondsPer100: Double
}

/// The full result of a stats computation.
struct StatsResult {
    var sessionCount: Int = 0
    var totalDistanceMeters: Double = 0
    var totalDurationSeconds: Int = 0
    var longestSwimMeters: Double = 0
    var averagePacePer100: Double = 0
    var currentStreakWeeks: Int = 0
    var strokeSlices: [StrokeSlice] = []
    var weeklyDistance: [DistancePoint] = []
    var paceTrend: [PacePoint] = []

    var isEmpty: Bool { sessionCount == 0 }
}

/// Computes lifetime and period statistics from completed sessions.
enum StatsEngine {

    static func compute(sessions: [SwimSession],
                        period: StatsPeriod,
                        calendar: Calendar = .current,
                        now: Date = .now) -> StatsResult {
        let scoped = filter(sessions, period: period, calendar: calendar, now: now)
        guard !scoped.isEmpty else { return StatsResult() }

        var result = StatsResult()
        result.sessionCount = scoped.count
        result.totalDistanceMeters = scoped.reduce(0) { $0 + max(0, $1.totalDistanceMeters) }
        result.totalDurationSeconds = scoped.reduce(0) { $0 + max(0, $1.durationSeconds) }
        result.longestSwimMeters = scoped.map { max(0, $0.totalDistanceMeters) }.max() ?? 0

        // Average pace per 100 across sessions that have both distance and time.
        var paceValues: [Double] = []
        for session in scoped {
            if let pace = SwimMath.pacePer100(seconds: Double(session.durationSeconds),
                                              distanceMeters: session.totalDistanceMeters) {
                paceValues.append(pace)
            }
        }
        if !paceValues.isEmpty {
            result.averagePacePer100 = paceValues.reduce(0, +) / Double(paceValues.count)
        }

        result.strokeSlices = strokeDistribution(scoped)
        result.weeklyDistance = weeklyDistance(scoped, calendar: calendar)
        result.paceTrend = paceTrend(scoped)
        result.currentStreakWeeks = weeklyStreak(scoped, calendar: calendar, now: now)
        return result
    }

    // MARK: - Components

    static func filter(_ sessions: [SwimSession],
                       period: StatsPeriod,
                       calendar: Calendar,
                       now: Date) -> [SwimSession] {
        guard let days = period.days else { return sessions }
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: now) else { return sessions }
        return sessions.filter { $0.date >= cutoff }
    }

    static func strokeDistribution(_ sessions: [SwimSession]) -> [StrokeSlice] {
        var totals: [Stroke: Double] = [:]
        for session in sessions {
            for set in session.orderedSets {
                totals[set.stroke, default: 0] += max(0, set.totalDistanceMeters)
            }
        }
        return totals
            .filter { $0.value > 0 }
            .map { StrokeSlice(stroke: $0.key, distanceMeters: $0.value) }
            .sorted { $0.distanceMeters > $1.distanceMeters }
    }

    static func weeklyDistance(_ sessions: [SwimSession], calendar: Calendar) -> [DistancePoint] {
        var buckets: [Date: Double] = [:]
        for session in sessions {
            let start = weekStart(for: session.date, calendar: calendar)
            buckets[start, default: 0] += max(0, session.totalDistanceMeters)
        }
        return buckets
            .map { DistancePoint(weekStart: $0.key, distanceMeters: $0.value) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    static func paceTrend(_ sessions: [SwimSession]) -> [PacePoint] {
        sessions
            .sorted { $0.date < $1.date }
            .compactMap { session in
                guard let pace = SwimMath.pacePer100(seconds: Double(session.durationSeconds),
                                                     distanceMeters: session.totalDistanceMeters) else {
                    return nil
                }
                return PacePoint(date: session.date, secondsPer100: pace)
            }
    }

    /// Count of consecutive weeks (ending this week or last) with at least one swim.
    static func weeklyStreak(_ sessions: [SwimSession], calendar: Calendar, now: Date) -> Int {
        guard !sessions.isEmpty else { return 0 }
        let swamWeeks = Set(sessions.map { weekStart(for: $0.date, calendar: calendar) })
        var cursor = weekStart(for: now, calendar: calendar)
        var streak = 0

        // Allow the streak to start from this week or the previous one.
        if !swamWeeks.contains(cursor) {
            guard let prev = calendar.date(byAdding: .day, value: -7, to: cursor) else { return 0 }
            if swamWeeks.contains(prev) {
                cursor = prev
            } else {
                return 0
            }
        }
        while swamWeeks.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -7, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    static func weekStart(for date: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: comps) ?? date
    }

    /// A fun, sharable milestone derived from total distance.
    /// "X lengths of an Olympic pool" (50 m).
    static func olympicLengths(_ meters: Double) -> Int {
        guard meters > 0 else { return 0 }
        return Int((meters / 50.0).rounded(.down))
    }

    /// Channel-crossing progress (English Channel ≈ 33,800 m) as a percentage 0...100+.
    static func channelPercent(_ meters: Double) -> Double {
        guard meters > 0 else { return 0 }
        return (meters / 33_800.0) * 100.0
    }
}
