import Foundation

/// A pure, guarded analytics engine over an array of `DayLog`s. No SwiftUI, no SwiftData
/// queries — fully testable. Every division is guarded; no force-unwraps or unchecked indices.
struct InsightsEngine {

    // MARK: - Inputs

    /// Logs sorted ascending by day. We snapshot the values we need (DayLog is a reference type).
    struct DaySnapshot: Identifiable {
        let id: UUID
        let date: Date
        let hotFlashCount: Int
        let nightSweats: Bool
        let mood: Int
        let sleepQuality: Int
        let energy: Int
        let flowIntensity: Int
        let isBleeding: Bool
        let symptoms: [String: Int]

        init(_ log: DayLog) {
            id = log.id
            date = log.date
            hotFlashCount = max(0, log.hotFlashCount)
            nightSweats = log.nightSweats
            mood = log.mood
            sleepQuality = log.sleepQuality
            energy = log.energy
            flowIntensity = log.flow.intensity
            isBleeding = log.flow.isBleeding
            symptoms = log.symptoms
        }
    }

    let days: [DaySnapshot]

    init(logs: [DayLog]) {
        self.days = logs
            .map(DaySnapshot.init)
            .sorted { $0.date < $1.date }
    }

    var isEmpty: Bool { days.isEmpty }

    // MARK: - Hot-flash series

    struct DayValue: Identifiable {
        let id: UUID
        let date: Date
        let value: Double
    }

    /// Per-day hot-flash counts over the most recent `window` days (calendar-filled, missing = 0).
    func hotFlashSeries(lastDays window: Int = 30) -> [DayValue] {
        filledSeries(lastDays: window) { Double($0.hotFlashCount) }
    }

    /// 7-day trailing average of hot flashes, aligned to `hotFlashSeries`.
    func hotFlashRollingAverage(lastDays window: Int = 30, avgWindow: Int = 7) -> [DayValue] {
        let series = filledSeries(lastDays: window + avgWindow) { Double($0.hotFlashCount) }
        guard !series.isEmpty else { return [] }
        var out: [DayValue] = []
        for i in series.indices {
            let lo = max(0, i - (avgWindow - 1))
            let slice = series[lo...i]
            let avg = slice.isEmpty ? 0 : slice.map(\.value).reduce(0, +) / Double(slice.count)
            out.append(DayValue(id: series[i].id, date: series[i].date, value: avg))
        }
        // Trim back to the requested window length.
        if out.count > window {
            return Array(out.suffix(window))
        }
        return out
    }

    /// Week-over-week change in hot-flash totals: (this 7 days) vs (prior 7 days). Returns a delta and direction.
    struct Trend {
        let current: Double
        let previous: Double
        var delta: Double { current - previous }
        var direction: TrendDirection {
            let d = delta
            if abs(d) < 0.5 { return .flat }
            return d > 0 ? .up : .down
        }
    }

    enum TrendDirection { case up, down, flat }

    func hotFlashWeekOverWeek() -> Trend {
        let recent = totalHotFlashes(daysAgo: 0..<7)
        let prior = totalHotFlashes(daysAgo: 7..<14)
        return Trend(current: recent, previous: prior)
    }

    private func totalHotFlashes(daysAgo range: Range<Int>) -> Double {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var sum = 0.0
        for d in days {
            let diff = cal.dateComponents([.day], from: d.date, to: today).day ?? Int.max
            if range.contains(diff) { sum += Double(d.hotFlashCount) }
        }
        return sum
    }

    // MARK: - Domain severity index (Greene-style)

    /// Total raw severity per domain across all logged days.
    func domainTotals() -> [(domain: SymptomDomain, total: Int)] {
        var totals: [SymptomDomain: Int] = [:]
        for d in days {
            for (key, sev) in d.symptoms {
                guard let domain = SymptomCatalog.domain(forKey: key) else { continue }
                totals[domain, default: 0] += sev
            }
        }
        return SymptomDomain.allCases.map { ($0, totals[$0] ?? 0) }
    }

    /// Per-day, per-domain severity sum — for trend lines. Filled to the recent window.
    struct DomainSeries: Identifiable {
        let id: String
        let domain: SymptomDomain
        let points: [DayValue]
    }

    func domainSeverityTrends(lastDays window: Int = 30) -> [DomainSeries] {
        SymptomDomain.allCases.map { domain in
            let pts = filledSeries(lastDays: window) { snap in
                var sum = 0
                for (key, sev) in snap.symptoms where SymptomCatalog.domain(forKey: key) == domain {
                    sum += sev
                }
                return Double(sum)
            }
            return DomainSeries(id: domain.rawValue, domain: domain, points: pts)
        }
    }

    // MARK: - Top symptoms

    struct SymptomRank: Identifiable {
        let id: String
        let name: String
        let domain: SymptomDomain
        /// Number of days the symptom appeared at severity ≥ 1.
        let daysPresent: Int
        /// Average severity on days it was present (1–3).
        let avgSeverity: Double
        /// Combined score = frequency × average severity (drives ranking).
        var score: Double { Double(daysPresent) * avgSeverity }
    }

    func topSymptoms(limit: Int = 6) -> [SymptomRank] {
        guard !days.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        var sums: [String: Int] = [:]
        for d in days {
            for (key, sev) in d.symptoms where sev >= 1 {
                counts[key, default: 0] += 1
                sums[key, default: 0] += sev
            }
        }
        let ranks: [SymptomRank] = counts.compactMap { key, count in
            guard let symptom = SymptomCatalog.symptom(forKey: key), count > 0 else { return nil }
            let avg = Double(sums[key] ?? 0) / Double(count)
            return SymptomRank(id: key, name: symptom.name, domain: symptom.domain,
                               daysPresent: count, avgSeverity: avg)
        }
        return ranks.sorted { $0.score > $1.score }.prefix(limit).map { $0 }
    }

    // MARK: - Mood & sleep trends

    func moodSeries(lastDays window: Int = 30) -> [DayValue] {
        filledSeriesOptional(lastDays: window) { snap in
            // Only count days that were actually logged (non-neutral or any content).
            Double(snap.mood)
        }
    }

    func sleepSeries(lastDays window: Int = 30) -> [DayValue] {
        filledSeriesOptional(lastDays: window) { snap in Double(snap.sleepQuality) }
    }

    func averageMood() -> Double? { averageRating(\.mood) }
    func averageSleep() -> Double? { averageRating(\.sleepQuality) }
    func averageEnergy() -> Double? { averageRating(\.energy) }

    private func averageRating(_ keyPath: KeyPath<DaySnapshot, Int>) -> Double? {
        let vals = days.map { $0[keyPath: keyPath] }.filter { $0 >= 1 && $0 <= 5 }
        guard !vals.isEmpty else { return nil }
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    // MARK: - Sleep ↔ hot-flash correlation

    struct SleepCorrelation {
        let poorSleepAvgHotFlashes: Double
        let goodSleepAvgHotFlashes: Double
        let poorSleepDays: Int
        let goodSleepDays: Int

        var hasSignal: Bool { poorSleepDays >= 3 && goodSleepDays >= 3 }
        /// Positive = more hot flashes on poor-sleep nights.
        var difference: Double { poorSleepAvgHotFlashes - goodSleepAvgHotFlashes }
    }

    /// Compares hot-flash counts on poor-sleep days (quality ≤ 2) vs good-sleep days (quality ≥ 4).
    func sleepHotFlashCorrelation() -> SleepCorrelation {
        var poorSum = 0.0, goodSum = 0.0
        var poorN = 0, goodN = 0
        for d in days {
            if d.sleepQuality <= 2 { poorSum += Double(d.hotFlashCount); poorN += 1 }
            else if d.sleepQuality >= 4 { goodSum += Double(d.hotFlashCount); goodN += 1 }
        }
        let poorAvg = poorN > 0 ? poorSum / Double(poorN) : 0
        let goodAvg = goodN > 0 ? goodSum / Double(goodN) : 0
        return SleepCorrelation(poorSleepAvgHotFlashes: poorAvg,
                                goodSleepAvgHotFlashes: goodAvg,
                                poorSleepDays: poorN, goodSleepDays: goodN)
    }

    // MARK: - Cycle awareness

    struct CycleInfo {
        let lastPeriodDate: Date?
        let daysSinceLastPeriod: Int?
        /// Longest gap (in days) between consecutive bleeding episodes within the data.
        let longestGap: Int?
        let stage: Stage
    }

    /// Clearly-informational stage heuristic — NOT a diagnosis.
    enum Stage: String {
        case tracking = "Getting started"
        case perimenopause = "Perimenopause (likely)"
        case lateTransition = "Late transition"
        case postmenopauseMilestone = "Postmenopause milestone"

        var explanation: String {
            switch self {
            case .tracking:
                return "Keep logging a few weeks and Equinox will surface your cycle patterns here."
            case .perimenopause:
                return "Your cycles look irregular with periods still occurring — a pattern often seen in perimenopause."
            case .lateTransition:
                return "It's been a while since your last period, but under 12 months — often called the late menopause transition."
            case .postmenopauseMilestone:
                return "You've logged 12+ months without a period — the clinical milestone for postmenopause. Worth noting with your clinician."
            }
        }
    }

    func cycleInfo() -> CycleInfo {
        let cal = Calendar.current
        let bleedingDays = days.filter { $0.isBleeding }.map(\.date).sorted()

        // Collapse consecutive bleeding days into episodes (start of each episode).
        var episodeStarts: [Date] = []
        var lastDate: Date?
        for d in bleedingDays {
            if let prev = lastDate {
                let gap = cal.dateComponents([.day], from: prev, to: d).day ?? 0
                if gap > 2 { episodeStarts.append(d) }
            } else {
                episodeStarts.append(d)
            }
            lastDate = d
        }

        let lastBleed = bleedingDays.last
        let today = cal.startOfDay(for: Date())
        let daysSince: Int? = lastBleed.map { cal.dateComponents([.day], from: $0, to: today).day ?? 0 }

        // Longest gap between episode starts.
        var longest: Int? = nil
        if episodeStarts.count >= 2 {
            var maxGap = 0
            for i in 1..<episodeStarts.count {
                let g = cal.dateComponents([.day], from: episodeStarts[i - 1], to: episodeStarts[i]).day ?? 0
                maxGap = max(maxGap, g)
            }
            longest = maxGap
        }

        let stage = computeStage(daysSince: daysSince, longestGap: longest, episodeCount: episodeStarts.count)
        return CycleInfo(lastPeriodDate: lastBleed,
                         daysSinceLastPeriod: daysSince,
                         longestGap: longest,
                         stage: stage)
    }

    private func computeStage(daysSince: Int?, longestGap: Int?, episodeCount: Int) -> Stage {
        guard let daysSince else { return .tracking }
        if daysSince >= 365 { return .postmenopauseMilestone }
        if daysSince >= 90 { return .lateTransition }
        // Irregularity signal: a long gap relative to a "typical" ~28-day cycle.
        if let g = longestGap, g >= 38, episodeCount >= 2 { return .perimenopause }
        if episodeCount >= 2 { return .perimenopause }
        return .tracking
    }

    // MARK: - Streak

    /// Consecutive days up to today with a logged, content-bearing day.
    func loggingStreak() -> Int {
        let cal = Calendar.current
        let logged = Set(days.map { cal.startOfDay(for: $0.date) })
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while logged.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    // MARK: - Aggregate summary (doctor report)

    struct Summary {
        let rangeStart: Date?
        let rangeEnd: Date?
        let daysLogged: Int
        let avgHotFlashesPerDay: Double
        let totalHotFlashes: Int
        let nightSweatDays: Int
        let topSymptoms: [SymptomRank]
        let avgMood: Double?
        let avgSleep: Double?
        let cycle: CycleInfo
    }

    func summary() -> Summary {
        let dates = days.map(\.date)
        let total = days.map(\.hotFlashCount).reduce(0, +)
        let avg = days.isEmpty ? 0 : Double(total) / Double(days.count)
        let nightSweatDays = days.filter(\.nightSweats).count
        return Summary(rangeStart: dates.min(),
                       rangeEnd: dates.max(),
                       daysLogged: days.count,
                       avgHotFlashesPerDay: avg,
                       totalHotFlashes: total,
                       nightSweatDays: nightSweatDays,
                       topSymptoms: topSymptoms(limit: 5),
                       avgMood: averageMood(),
                       avgSleep: averageSleep(),
                       cycle: cycleInfo())
    }

    // MARK: - Series helpers (calendar-filled)

    /// Builds a continuous daily series over the last `window` days, filling missing days with 0.
    private func filledSeries(lastDays window: Int, value: (DaySnapshot) -> Double) -> [DayValue] {
        guard window > 0 else { return [] }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var byDate: [Date: DaySnapshot] = [:]
        for d in days { byDate[cal.startOfDay(for: d.date)] = d }

        var out: [DayValue] = []
        for offset in stride(from: window - 1, through: 0, by: -1) {
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            if let snap = byDate[day] {
                out.append(DayValue(id: snap.id, date: day, value: value(snap)))
            } else {
                out.append(DayValue(id: UUID(), date: day, value: 0))
            }
        }
        return out
    }

    /// Like `filledSeries` but skips unlogged days entirely (used for mood/sleep where 0 ≠ meaningful).
    private func filledSeriesOptional(lastDays window: Int, value: (DaySnapshot) -> Double) -> [DayValue] {
        guard window > 0 else { return [] }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let cutoff = cal.date(byAdding: .day, value: -(window - 1), to: today) ?? today
        return days
            .filter { $0.date >= cutoff }
            .map { DayValue(id: $0.id, date: $0.date, value: value($0)) }
    }
}
