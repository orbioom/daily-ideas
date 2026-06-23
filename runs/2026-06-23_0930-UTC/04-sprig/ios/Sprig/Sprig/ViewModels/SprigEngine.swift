import Foundation

/// A unified, sortable representation of any logged event for the timeline.
struct TimelineItem: Identifiable, Hashable {
    enum Source: Hashable { case feed, sleep, diaper, growth }

    let id: UUID
    let date: Date
    let source: Source

    init(id: UUID, date: Date, source: Source) {
        self.id = id
        self.date = date
        self.source = source
    }
}

/// A single day's roll-up of counts, used for summaries and charts.
struct DaySummary: Identifiable {
    let id = UUID()
    let day: Date
    var feedCount: Int = 0
    var bottleML: Double = 0
    var breastSeconds: Int = 0
    var sleepSeconds: Double = 0
    var diaperCount: Int = 0
    var wetCount: Int = 0
    var dirtyCount: Int = 0

    var sleepHours: Double { sleepSeconds / 3600 }
}

/// Pure functions deriving summaries and chart series from a baby's logs.
/// No state, no I/O — fully testable and crash-proof (all division guarded).
enum SprigEngine {

    private static var cal: Calendar { Calendar.current }

    // MARK: - Timeline

    /// Merge a baby's logs into one reverse-chronological timeline.
    static func timeline(for baby: Baby) -> [TimelineItem] {
        var items: [TimelineItem] = []
        items.reserveCapacity(baby.feeds.count + baby.sleeps.count + baby.diapers.count + baby.growth.count)
        for f in baby.feeds { items.append(.init(id: f.id, date: f.date, source: .feed)) }
        for s in baby.sleeps { items.append(.init(id: s.id, date: s.start, source: .sleep)) }
        for d in baby.diapers { items.append(.init(id: d.id, date: d.date, source: .diaper)) }
        for g in baby.growth { items.append(.init(id: g.id, date: g.date, source: .growth)) }
        return items.sorted { $0.date > $1.date }
    }

    // MARK: - Last events

    static func lastFeed(for baby: Baby) -> FeedLog? {
        baby.feeds.max { $0.date < $1.date }
    }

    static func lastSleep(for baby: Baby) -> SleepLog? {
        baby.sleeps.max { $0.start < $1.start }
    }

    static func lastDiaper(for baby: Baby) -> DiaperLog? {
        baby.diapers.max { $0.date < $1.date }
    }

    /// Any currently running sleep session.
    static func ongoingSleep(for baby: Baby) -> SleepLog? {
        baby.sleeps.first { $0.isOngoing }
    }

    // MARK: - Today summary

    static func summary(for baby: Baby, on day: Date = Date()) -> DaySummary {
        var summary = DaySummary(day: cal.startOfDay(for: day))
        let isSameDay: (Date) -> Bool = { cal.isDate($0, inSameDayAs: day) }

        for f in baby.feeds where isSameDay(f.date) {
            summary.feedCount += 1
            summary.bottleML += f.volumeML
            summary.breastSeconds += f.durationSeconds
        }
        for s in baby.sleeps where isSameDay(s.start) {
            summary.sleepSeconds += s.duration()
        }
        for d in baby.diapers where isSameDay(d.date) {
            summary.diaperCount += 1
            switch d.kind {
            case .wet: summary.wetCount += 1
            case .dirty: summary.dirtyCount += 1
            case .mixed: summary.wetCount += 1; summary.dirtyCount += 1
            case .dry: break
            }
        }
        return summary
    }

    // MARK: - Multi-day series

    /// Build day-by-day summaries for the last `days` days, oldest first.
    static func dailySeries(for baby: Baby, days: Int = 14, ending: Date = Date()) -> [DaySummary] {
        let span = max(1, days)
        let end = cal.startOfDay(for: ending)
        var result: [DaySummary] = []
        result.reserveCapacity(span)
        for offset in stride(from: span - 1, through: 0, by: -1) {
            if let day = cal.date(byAdding: .day, value: -offset, to: end) {
                result.append(summary(for: baby, on: day))
            }
        }
        return result
    }

    // MARK: - Growth series

    struct GrowthPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    static func weightSeries(for baby: Baby) -> [GrowthPoint] {
        baby.growth
            .filter { $0.hasWeight }
            .sorted { $0.date < $1.date }
            .map { GrowthPoint(date: $0.date, value: $0.weightGrams) }
    }

    static func lengthSeries(for baby: Baby) -> [GrowthPoint] {
        baby.growth
            .filter { $0.hasLength }
            .sorted { $0.date < $1.date }
            .map { GrowthPoint(date: $0.date, value: $0.lengthCM) }
    }

    /// Total weight gain in grams between first and latest weight entry.
    static func weightGain(for baby: Baby) -> Double? {
        let pts = weightSeries(for: baby)
        guard let first = pts.first, let last = pts.last, pts.count >= 2 else { return nil }
        return last.value - first.value
    }

    // MARK: - Averages (guarded division)

    /// Average daily feeds over the series window.
    static func avgFeedsPerDay(_ series: [DaySummary]) -> Double {
        guard !series.isEmpty else { return 0 }
        let total = series.reduce(0) { $0 + $1.feedCount }
        return Double(total) / Double(series.count)
    }

    static func avgSleepHours(_ series: [DaySummary]) -> Double {
        guard !series.isEmpty else { return 0 }
        let total = series.reduce(0.0) { $0 + $1.sleepHours }
        return total / Double(series.count)
    }

    static func avgDiapersPerDay(_ series: [DaySummary]) -> Double {
        guard !series.isEmpty else { return 0 }
        let total = series.reduce(0) { $0 + $1.diaperCount }
        return Double(total) / Double(series.count)
    }
}
