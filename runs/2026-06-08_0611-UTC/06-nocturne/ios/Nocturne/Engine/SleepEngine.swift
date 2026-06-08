import Foundation

/// Pure, stateless sleep analytics engine.
/// All functions are side-effect-free and operate over [SleepLog] slices.
enum SleepEngine {

    // MARK: - Duration

    static func durationHours(_ log: SleepLog) -> Double {
        log.durationHours
    }

    // MARK: - Averages

    static func averageDuration(logs: [SleepLog], lastN: Int? = nil) -> Double? {
        let slice = lastN.map { Array(logs.prefix($0)) } ?? logs
        guard !slice.isEmpty else { return nil }
        let total = slice.reduce(0.0) { $0 + $1.durationHours }
        return total / Double(slice.count)
    }

    // MARK: - Sleep Debt

    /// Returns total deficit hours over up to `window` most-recent nights present.
    /// Nights that beat the target reduce the running debt (rolling model).
    static func sleepDebt(logs: [SleepLog], targetHours: Double, window: Int = 14) -> Double {
        let slice = Array(logs.prefix(window))
        guard !slice.isEmpty else { return 0 }
        let deficit = slice.reduce(0.0) { acc, log in
            acc + (targetHours - log.durationHours)
        }
        return max(0, deficit)
    }

    /// Rolling debt (can be negative = well-rested buffer).
    static func rollingDebt(logs: [SleepLog], targetHours: Double, window: Int = 14) -> Double {
        let slice = Array(logs.prefix(window))
        guard !slice.isEmpty else { return 0 }
        let expected = targetHours * Double(slice.count)
        let actual = slice.reduce(0.0) { $0 + $1.durationHours }
        return expected - actual
    }

    static func debtLabel(debt: Double) -> String {
        if debt <= 0 { return "Well-rested" }
        if debt < 1  { return "Slight deficit" }
        if debt < 3  { return "Moderate debt" }
        return "High debt"
    }

    // MARK: - Regularity Score

    /// Score 0…100 based on variability of bedtime and wake-time across last N nights.
    /// Uses a circular-mean approach to handle midnight crossings.
    /// Lower stdev in minutes → higher score.
    static func regularityScore(logs: [SleepLog], lastN: Int = 14) -> Int {
        let slice = Array(logs.prefix(lastN))
        guard slice.count >= 2 else { return slice.isEmpty ? 0 : 100 }

        let bedStdev  = circularMinuteStdev(slice.map { bedtimeMinutesOfDay($0.bedTime) })
        let wakeStdev = circularMinuteStdev(slice.map { minutesOfDay($0.wakeTime) })

        let combined = (bedStdev + wakeStdev) / 2.0
        // k = 1.4 means 72 min stdev → score 0; 0 stdev → score 100
        let k = 1.4
        let score = max(0.0, 100.0 - combined * k)
        return Int(score.rounded())
    }

    // MARK: - Average Bedtime / Waketime

    static func averageBedtimeMinutes(logs: [SleepLog], lastN: Int = 14) -> Int? {
        let slice = Array(logs.prefix(lastN))
        guard !slice.isEmpty else { return nil }
        let minutes = slice.map { bedtimeMinutesOfDay($0.bedTime) }
        return circularMeanMinutes(minutes)
    }

    static func averageWaketimeMinutes(logs: [SleepLog], lastN: Int = 14) -> Int? {
        let slice = Array(logs.prefix(lastN))
        guard !slice.isEmpty else { return nil }
        let minutes = slice.map { minutesOfDay($0.wakeTime) }
        return circularMeanMinutes(minutes)
    }

    // MARK: - Recommended Bedtime

    /// Returns minutes-of-day for recommended bedtime = targetWake minus targetHours.
    static func recommendedBedtimeMinutes(targetWakeMinutes: Int, targetHours: Double) -> Int {
        let totalMinutes = Int(targetHours * 60)
        var result = targetWakeMinutes - totalMinutes
        while result < 0 { result += 1440 }
        return result % 1440
    }

    // MARK: - Goal Streak

    /// Consecutive recent nights (newest first) where durationHours >= targetHours.
    static func goalStreak(logs: [SleepLog], targetHours: Double) -> Int {
        var streak = 0
        for log in logs {
            if log.durationHours >= targetHours {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Quality

    static func qualityDistribution(logs: [SleepLog]) -> [Int: Int] {
        var dist: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for log in logs {
            dist[log.quality, default: 0] += 1
        }
        return dist
    }

    static func averageQuality(logs: [SleepLog]) -> Double? {
        guard !logs.isEmpty else { return nil }
        let total = logs.reduce(0) { $0 + $1.quality }
        return Double(total) / Double(logs.count)
    }

    static func averageAwakenings(logs: [SleepLog]) -> Double? {
        guard !logs.isEmpty else { return nil }
        let total = logs.reduce(0) { $0 + $1.awakenings }
        return Double(total) / Double(logs.count)
    }

    // MARK: - Tag Correlation

    /// Returns a list of (tag, avgDurationWith, avgDurationWithout) sorted by tag name.
    static func tagCorrelations(logs: [SleepLog]) -> [(tag: String, withTag: Double, withoutTag: Double)] {
        let allTags = Set(logs.flatMap { $0.tags })
        guard !logs.isEmpty else { return [] }
        return allTags.compactMap { tag in
            let with_    = logs.filter { $0.tags.contains(tag) }
            let without  = logs.filter { !$0.tags.contains(tag) }
            guard let avgWith    = averageDuration(logs: with_),
                  let avgWithout = averageDuration(logs: without) else { return nil }
            return (tag: tag, withTag: avgWith, withoutTag: avgWithout)
        }.sorted { $0.tag < $1.tag }
    }

    // MARK: - Debt per Night (for history row)

    static func debtContribution(_ log: SleepLog, targetHours: Double) -> Double {
        targetHours - log.durationHours   // negative = surplus
    }

    // MARK: - Helpers (internal)

    /// Minutes of day (0…1439) for wake time.
    static func minutesOfDay(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    /// Minutes of day for bedtime, shifted by +12h so that 22:00–02:00 clusters
    /// map to a contiguous arc rather than wrapping midnight.
    static func bedtimeMinutesOfDay(_ date: Date) -> Int {
        let raw = minutesOfDay(date)
        return (raw + 720) % 1440   // shift by 12h
    }

    /// Circular mean of minute values (0…1439).
    static func circularMeanMinutes(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        let twoPi  = 2.0 * Double.pi
        let n      = Double(values.count)
        let sinSum = values.reduce(0.0) { $0 + sin(Double($1) / 1440.0 * twoPi) }
        let cosSum = values.reduce(0.0) { $0 + cos(Double($1) / 1440.0 * twoPi) }
        let angle  = atan2(sinSum / n, cosSum / n)
        let norm   = (angle < 0 ? angle + twoPi : angle) / twoPi
        return Int((norm * 1440).rounded()) % 1440
    }

    /// Circular standard deviation of minute values (0…1439), returned in minutes.
    static func circularMinuteStdev(_ values: [Int]) -> Double {
        guard values.count >= 2 else { return 0 }
        let twoPi  = 2.0 * Double.pi
        let n      = Double(values.count)
        let sinSum = values.reduce(0.0) { $0 + sin(Double($1) / 1440.0 * twoPi) }
        let cosSum = values.reduce(0.0) { $0 + cos(Double($1) / 1440.0 * twoPi) }
        let R      = sqrt(sinSum * sinSum + cosSum * cosSum) / n
        let Rclamped = min(1.0, max(0.0, R))
        // Circular stdev in radians, converted to minutes
        let stdevRad = sqrt(-2.0 * log(Rclamped))
        return stdevRad / twoPi * 1440.0
    }
}
