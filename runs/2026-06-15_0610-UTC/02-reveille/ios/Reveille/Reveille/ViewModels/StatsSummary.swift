import Foundation

/// A Sendable snapshot of a WakeLog so stats can be computed off the main actor.
struct WakeLogLite: Sendable {
    let date: Date
    let firedAt: Date
    let secondsToDismiss: Int
    let snoozeCount: Int
    let missionTypeRaw: String
}

/// One point in the time-to-dismiss trend (per wake event, chronological).
struct DismissPoint: Identifiable, Sendable {
    let id: Int
    let index: Int
    let date: Date
    let seconds: Int
}

/// One bar in the snoozes-per-week series.
struct SnoozeWeek: Identifiable, Sendable {
    let id: Int
    let weekLabel: String
    let snoozes: Int
}

/// One slice of the wake-time consistency (how spread out your wake clock-times are by hour).
struct WakeHourBin: Identifiable, Sendable {
    let id: Int
    let hour: Int
    let count: Int
    var label: String {
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "a" : "p"
        return "\(h12)\(suffix)"
    }
}

/// All computed wake-up stats. Built off the main actor from `WakeLogLite`s.
struct StatsSummary: Sendable {
    let totalWakes: Int
    let avgSecondsToDismiss: Int
    let avgSnoozes: Double
    let totalSnoozes: Int
    let missionsCompleted: Int
    let consistencyLabel: String          // e.g. "±18 min" spread of wake times
    let bestStreakDays: Int

    let dismissTrend: [DismissPoint]
    let snoozesByWeek: [SnoozeWeek]
    let wakeHours: [WakeHourBin]

    static func empty() -> StatsSummary {
        StatsSummary(totalWakes: 0, avgSecondsToDismiss: 0, avgSnoozes: 0, totalSnoozes: 0,
                     missionsCompleted: 0, consistencyLabel: "—", bestStreakDays: 0,
                     dismissTrend: [], snoozesByWeek: [], wakeHours: [])
    }

    static func build(from logs: [WakeLogLite], calendar: Calendar = .current) -> StatsSummary {
        guard !logs.isEmpty else { return .empty() }
        let count = logs.count

        // Averages (guard all divisions).
        let totalSeconds = logs.reduce(0) { $0 + max(0, $1.secondsToDismiss) }
        let avgSeconds = count > 0 ? totalSeconds / count : 0
        let totalSnoozes = logs.reduce(0) { $0 + max(0, $1.snoozeCount) }
        let avgSnoozes = count > 0 ? Double(totalSnoozes) / Double(count) : 0
        let missionsCompleted = logs.filter { $0.missionTypeRaw != MissionType.none.rawValue }.count

        // Dismiss trend: chronological, most recent up to 30.
        let chronological = logs.sorted { $0.firedAt < $1.firedAt }
        let recent = Array(chronological.suffix(30))
        let dismissTrend = recent.enumerated().map { i, l in
            DismissPoint(id: i, index: i, date: l.firedAt, seconds: max(0, l.secondsToDismiss))
        }

        // Snoozes by week (last 6 ISO weeks present in the data).
        var weekBuckets: [Date: Int] = [:]
        for l in logs {
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: l.firedAt)
            if let weekStart = calendar.date(from: comps) {
                weekBuckets[weekStart, default: 0] += max(0, l.snoozeCount)
            }
        }
        let sortedWeeks = weekBuckets.keys.sorted()
        let lastWeeks = Array(sortedWeeks.suffix(6))
        let snoozesByWeek = lastWeeks.enumerated().map { i, week -> SnoozeWeek in
            let label = week.formatted(.dateTime.month(.abbreviated).day())
            return SnoozeWeek(id: i, weekLabel: label, snoozes: weekBuckets[week] ?? 0)
        }

        // Wake-hour histogram (consistency): which clock hour you actually got up.
        var hourCounts = [Int: Int]()
        var minutesOfDay: [Int] = []
        for l in logs {
            let comps = calendar.dateComponents([.hour, .minute], from: l.dismissedAtApprox)
            let hour = comps.hour ?? 0
            hourCounts[hour, default: 0] += 1
            minutesOfDay.append((comps.hour ?? 0) * 60 + (comps.minute ?? 0))
        }
        let wakeHours = (0..<24).map { h in
            WakeHourBin(id: h, hour: h, count: hourCounts[h] ?? 0)
        }

        // Consistency: standard deviation of wake clock-time in minutes.
        let consistencyLabel: String
        if minutesOfDay.count > 1 {
            let mean = Double(minutesOfDay.reduce(0, +)) / Double(minutesOfDay.count)
            let variance = minutesOfDay.reduce(0.0) { $0 + pow(Double($1) - mean, 2) } / Double(minutesOfDay.count)
            let std = Int(variance.squareRoot())
            consistencyLabel = "±\(std) min"
        } else {
            consistencyLabel = "—"
        }

        // Best streak: consecutive distinct days with a wake log.
        let days = Set(logs.map { calendar.startOfDay(for: $0.firedAt) }).sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in days {
            if let prev = previous,
               let next = calendar.date(byAdding: .day, value: 1, to: prev),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            previous = day
        }

        return StatsSummary(totalWakes: count,
                            avgSecondsToDismiss: avgSeconds,
                            avgSnoozes: avgSnoozes,
                            totalSnoozes: totalSnoozes,
                            missionsCompleted: missionsCompleted,
                            consistencyLabel: consistencyLabel,
                            bestStreakDays: best,
                            dismissTrend: dismissTrend,
                            snoozesByWeek: snoozesByWeek,
                            wakeHours: wakeHours)
    }
}

private extension WakeLogLite {
    /// Approximate dismissal wall-clock time = fired time + seconds-to-dismiss.
    var dismissedAtApprox: Date {
        firedAt.addingTimeInterval(Double(max(0, secondsToDismiss)))
    }
}

/// Format seconds as a friendly "1m 12s" / "48s" string. Guards negatives.
func formatDuration(_ seconds: Int) -> String {
    let s = max(0, seconds)
    if s < 60 { return "\(s)s" }
    let m = s / 60
    let r = s % 60
    return r == 0 ? "\(m)m" : "\(m)m \(r)s"
}
