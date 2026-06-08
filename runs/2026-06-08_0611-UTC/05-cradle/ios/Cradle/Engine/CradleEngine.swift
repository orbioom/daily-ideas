import Foundation

/// Pure stateless engine — no SwiftData, no UI imports.
/// All computations go here for testability and separation.
enum CradleEngine {

    // MARK: - Duration

    /// Safe duration for an event: (endTime ?? now) - startTime, clamped to >= 0.
    static func duration(event: CareEvent, now: Date = Date()) -> TimeInterval {
        let end = event.endTime ?? now
        return max(0, end.timeIntervalSince(event.startTime))
    }

    // MARK: - Time Since

    /// Seconds since a given date.
    static func timeSince(_ date: Date, now: Date = Date()) -> TimeInterval {
        max(0, now.timeIntervalSince(date))
    }

    // MARK: - Last Event

    static func lastEvent(of kind: EventKind, in events: [CareEvent]) -> CareEvent? {
        events
            .filter { $0.kind == kind }
            .max(by: { $0.startTime < $1.startTime })
    }

    // MARK: - Active Event

    /// An ongoing event is one with endTime == nil, for feed/sleep/pump only.
    static func activeEvent(in events: [CareEvent]) -> CareEvent? {
        events.first(where: {
            $0.endTime == nil && ($0.kind == .feed || $0.kind == .sleep || $0.kind == .pump)
        })
    }

    // MARK: - Day Summary

    struct DaySummary {
        var feeds: Int
        var totalSleep: TimeInterval
        var naps: Int
        var wetDiapers: Int
        var dirtyDiapers: Int
        var bottleML: Double
    }

    static func daySummary(events: [CareEvent], day: Date, now: Date = Date()) -> DaySummary {
        let cal = Calendar.current
        let dayEvents = events.filter { cal.isDate($0.startTime, inSameDayAs: day) }

        let feeds = dayEvents.filter { $0.kind == .feed }.count
        let sleepEvents = dayEvents.filter { $0.kind == .sleep }
        let totalSleep = sleepEvents.reduce(0.0) { $0 + duration(event: $1, now: now) }
        let naps = sleepEvents.count

        let diapers = dayEvents.filter { $0.kind == .diaper }
        let wetDiapers = diapers.filter { $0.diaperType == .wet || $0.diaperType == .mixed }.count
        let dirtyDiapers = diapers.filter { $0.diaperType == .dirty || $0.diaperType == .mixed }.count

        let bottleML = dayEvents
            .filter { $0.kind == .feed && $0.feedType == .bottle }
            .compactMap { $0.amountML }
            .reduce(0, +)

        return DaySummary(
            feeds: feeds,
            totalSleep: totalSleep,
            naps: naps,
            wetDiapers: wetDiapers,
            dirtyDiapers: dirtyDiapers,
            bottleML: bottleML
        )
    }

    // MARK: - Averages

    struct Averages {
        var feedsPerDay: Double
        var sleepHoursPerDay: Double
        var diapersPerDay: Double
    }

    static func averages(events: [CareEvent], lastNDays: Int, now: Date = Date()) -> Averages {
        guard lastNDays > 0 else {
            return Averages(feedsPerDay: 0, sleepHoursPerDay: 0, diapersPerDay: 0)
        }

        let cal = Calendar.current
        let days = (0..<lastNDays).compactMap { cal.date(byAdding: .day, value: -$0, to: now) }

        var totalFeeds = 0
        var totalSleep: TimeInterval = 0
        var totalDiapers = 0

        for day in days {
            let summary = daySummary(events: events, day: day, now: now)
            totalFeeds += summary.feeds
            totalSleep += summary.totalSleep
            totalDiapers += summary.wetDiapers + summary.dirtyDiapers
        }

        let n = Double(lastNDays)
        return Averages(
            feedsPerDay: totalFeeds / n,
            sleepHoursPerDay: (totalSleep / 3600.0) / n,
            diapersPerDay: Double(totalDiapers) / n
        )
    }

    // MARK: - Day vs Night Sleep

    struct SleepSplit {
        var daySleep: TimeInterval   // 07:00–18:59
        var nightSleep: TimeInterval // 19:00–06:59
    }

    /// Split sleep totals for a given day. Night = 19:00–06:59.
    static func dayVsNightSleep(events: [CareEvent], day: Date, now: Date = Date()) -> SleepSplit {
        let cal = Calendar.current
        let sleepEvents = events.filter {
            $0.kind == .sleep && cal.isDate($0.startTime, inSameDayAs: day)
        }

        var dayTotal: TimeInterval = 0
        var nightTotal: TimeInterval = 0

        for event in sleepEvents {
            let hour = cal.component(.hour, from: event.startTime)
            let dur = duration(event: event, now: now)
            // Night = 19:00–06:59
            if hour >= 19 || hour < 7 {
                nightTotal += dur
            } else {
                dayTotal += dur
            }
        }

        return SleepSplit(daySleep: dayTotal, nightSleep: nightTotal)
    }

    // MARK: - Per-day data for charts

    struct DayData: Identifiable {
        var id: Date { day }
        var day: Date
        var feeds: Int
        var sleepHours: Double
        var daySleepHours: Double
        var nightSleepHours: Double
        var diapers: Int
    }

    static func perDayData(events: [CareEvent], lastNDays: Int, now: Date = Date()) -> [DayData] {
        let cal = Calendar.current
        return (0..<lastNDays).compactMap { offset -> DayData? in
            guard let day = cal.date(byAdding: .day, value: -(lastNDays - 1 - offset), to: now) else { return nil }
            let summary = daySummary(events: events, day: day, now: now)
            let split = dayVsNightSleep(events: events, day: day, now: now)
            return DayData(
                day: cal.startOfDay(for: day),
                feeds: summary.feeds,
                sleepHours: summary.totalSleep / 3600.0,
                daySleepHours: split.daySleep / 3600.0,
                nightSleepHours: split.nightSleep / 3600.0,
                diapers: summary.wetDiapers + summary.dirtyDiapers
            )
        }
    }

    // MARK: - Average feed interval

    /// Mean time in hours between feeds over the last N days.
    static func averageFeedInterval(events: [CareEvent], lastNDays: Int, now: Date = Date()) -> Double? {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -lastNDays, to: now) else { return nil }
        let feedTimes = events
            .filter { $0.kind == .feed && $0.startTime >= cutoff }
            .map { $0.startTime }
            .sorted()
        guard feedTimes.count >= 2 else { return nil }
        var totalInterval: TimeInterval = 0
        for i in 1..<feedTimes.count {
            totalInterval += feedTimes[i].timeIntervalSince(feedTimes[i - 1])
        }
        let avgSeconds = totalInterval / Double(feedTimes.count - 1)
        return avgSeconds / 3600.0
    }

    // MARK: - Longest sleep

    static func longestSleep(events: [CareEvent], lastNDays: Int, now: Date = Date()) -> TimeInterval? {
        let cal = Calendar.current
        guard let cutoff = cal.date(byAdding: .day, value: -lastNDays, to: now) else { return nil }
        let durations = events
            .filter { $0.kind == .sleep && $0.startTime >= cutoff }
            .map { duration(event: $0, now: now) }
        return durations.max()
    }
}
