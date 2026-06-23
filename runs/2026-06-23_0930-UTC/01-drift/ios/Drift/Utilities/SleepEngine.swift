import Foundation

/// Pure, testable sleep math. No SwiftData, no SwiftUI — just inputs → numbers.
/// All time-of-day math is circular-aware (handles bedtimes after midnight).
enum SleepEngine {

    // MARK: - Sleep debt

    /// Rolling sleep debt over the trailing `window` nights, in hours.
    /// Positive = you owe sleep; negative = you are ahead (a small surplus).
    /// Debt is the sum of nightly shortfalls vs the goal, but a single great
    /// night cannot erase weeks of deficit, so surplus is capped per night.
    static func sleepDebt(
        logs: [SleepLog],
        goalHours: Double,
        window: Int = 14,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let recent = nights(logs: logs, window: window, now: now, calendar: calendar)
        guard !recent.isEmpty else { return 0 }
        var debt = 0.0
        for log in recent {
            let delta = goalHours - log.durationHours   // +ve = short
            if delta >= 0 {
                debt += delta
            } else {
                // Surplus pays down debt but each night caps recovery at 1h.
                debt += max(delta, -1.0)
            }
        }
        return max(0, debt)
    }

    /// Per-night debt series for charting (cumulative within the window).
    static func debtSeries(
        logs: [SleepLog],
        goalHours: Double,
        window: Int = 14,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [(night: Date, debt: Double)] {
        let recent = nights(logs: logs, window: window, now: now, calendar: calendar)
            .sorted { $0.night < $1.night }
        var running = 0.0
        var out: [(Date, Double)] = []
        for log in recent {
            let delta = goalHours - log.durationHours
            running += delta >= 0 ? delta : max(delta, -1.0)
            running = max(0, running)
            out.append((log.night, running))
        }
        return out.map { (night: $0.0, debt: $0.1) }
    }

    // MARK: - Consistency / regularity

    /// Consistency score 0...100 based on how tightly bedtimes and wake times
    /// cluster across the window. Lower variance → higher score.
    /// Uses circular statistics so 23:30 and 00:15 are treated as close.
    static func consistencyScore(
        logs: [SleepLog],
        window: Int = 14,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int {
        let recent = nights(logs: logs, window: window, now: now, calendar: calendar)
        guard recent.count >= 2 else { return recent.isEmpty ? 0 : 100 }

        let bedMinutes = recent.map { minuteOfDay($0.bedTime, calendar: calendar) }
        let wakeMinutes = recent.map { minuteOfDay($0.wakeTime, calendar: calendar) }

        let bedSpread = circularStdMinutes(bedMinutes)   // 0...~360
        let wakeSpread = circularStdMinutes(wakeMinutes)
        let avgSpread = (bedSpread + wakeSpread) / 2.0

        // Map: 0 min spread → 100, 90+ min spread → ~0. Smooth, clamped.
        let score = 100.0 * exp(-avgSpread / 60.0)
        return Int(round(max(0, min(100, score))))
    }

    // MARK: - Bedtime suggestion

    /// Recommended bedtime to hit `goalHours` of sleep before `wakeTime`,
    /// shifted by chronotype and optionally backed off for wind-down.
    /// Returns the suggested lights-out instant on tonight's clock.
    static func suggestedBedtime(
        wakeTime: Date,
        goalHours: Double,
        chronotype: Chronotype,
        windDownMinutes: Int,
        includeWindDown: Bool,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date {
        // Normalize wake time to the *next* occurrence after now.
        let wake = nextOccurrence(of: wakeTime, after: now, calendar: calendar)
        var bed = wake.addingTimeInterval(-goalHours * 3600)

        // Chronotype nudge: lions earlier, wolves later (minutes).
        let nudge: Double
        switch chronotype {
        case .lion: nudge = -20
        case .bear: nudge = 0
        case .wolf: nudge = 35
        case .dolphin: nudge = 10
        }
        bed = bed.addingTimeInterval(nudge * 60)
        return bed
    }

    /// The time the wind-down routine should begin (before suggested bedtime).
    static func windDownStart(
        bedtime: Date,
        windDownMinutes: Int
    ) -> Date {
        bedtime.addingTimeInterval(-Double(windDownMinutes) * 60)
    }

    // MARK: - Averages

    static func averageDuration(
        logs: [SleepLog],
        window: Int = 14,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let recent = nights(logs: logs, window: window, now: now, calendar: calendar)
        guard !recent.isEmpty else { return 0 }
        let total = recent.reduce(0.0) { $0 + $1.durationHours }
        return total / Double(recent.count)
    }

    static func averageQuality(
        logs: [SleepLog],
        window: Int = 14,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Double {
        let recent = nights(logs: logs, window: window, now: now, calendar: calendar)
        guard !recent.isEmpty else { return 0 }
        let total = recent.reduce(0) { $0 + $1.quality }
        return Double(total) / Double(recent.count)
    }

    // MARK: - Helpers

    /// Logs whose night falls within the trailing `window` days of `now`.
    static func nights(
        logs: [SleepLog],
        window: Int,
        now: Date,
        calendar: Calendar
    ) -> [SleepLog] {
        guard window > 0 else { return [] }
        let startDay = calendar.startOfDay(for: now)
        guard let cutoff = calendar.date(byAdding: .day, value: -(window - 1), to: startDay) else {
            return logs
        }
        let upperBound = calendar.date(byAdding: .day, value: 1, to: startDay) ?? now
        return logs.filter { $0.night >= cutoff && $0.night <= upperBound }
    }

    static func minuteOfDay(_ date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Circular standard deviation of minutes-of-day, returned in minutes.
    static func circularStdMinutes(_ minutes: [Int]) -> Double {
        guard !minutes.isEmpty else { return 0 }
        var sx = 0.0, sy = 0.0
        for m in minutes {
            let theta = Double(m) / 1440.0 * 2 * .pi
            sx += cos(theta); sy += sin(theta)
        }
        let n = Double(minutes.count)
        let r = sqrt(sx * sx + sy * sy) / n   // mean resultant length 0...1
        let clamped = min(max(r, 1e-9), 1.0)
        // Circular SD in radians → minutes.
        let sdRad = sqrt(-2.0 * log(clamped))
        return sdRad / (2 * .pi) * 1440.0
    }

    /// Next occurrence of the time-of-day in `template` strictly after `after`.
    static func nextOccurrence(of template: Date, after: Date, calendar: Calendar) -> Date {
        let comps = calendar.dateComponents([.hour, .minute], from: template)
        let today = calendar.nextDate(
            after: after,
            matching: comps,
            matchingPolicy: .nextTime,
            direction: .forward
        )
        return today ?? after.addingTimeInterval(8 * 3600)
    }
}
