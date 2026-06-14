import Foundation

/// Pure helpers for trip-day generation, sorting and countdowns.
/// All date math is done with calendar components to stay DST-safe.
enum ItineraryEngine {

    /// Calendar with the current time zone, midnight-anchored for day math.
    static var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal
    }

    /// Start-of-day for a given date.
    static func startOfDay(_ date: Date, calendar: Calendar = ItineraryEngine.calendar) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Inclusive list of calendar-day start dates between start and end.
    /// Guards against end < start (returns just the start day) and caps the
    /// span to a sane maximum to avoid runaway loops on corrupt input.
    static func dayDates(from start: Date,
                         to end: Date,
                         calendar: Calendar = ItineraryEngine.calendar) -> [Date] {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        guard e >= s else { return [s] }
        let maxDays = 366 * 2
        var result: [Date] = []
        var cursor = s
        var guardCount = 0
        while cursor <= e && guardCount <= maxDays {
            result.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            guardCount += 1
        }
        return result
    }

    /// Number of days in the trip (inclusive). Always >= 1.
    static func durationDays(start: Date,
                             end: Date,
                             calendar: Calendar = ItineraryEngine.calendar) -> Int {
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        guard e >= s else { return 1 }
        let comps = calendar.dateComponents([.day], from: s, to: e)
        return (comps.day ?? 0) + 1
    }

    /// Sort a day's items: timed first (ascending by start time, then sortOrder),
    /// untimed afterwards ordered by sortOrder then title.
    static func sortedItems(_ items: [ItineraryItem]) -> [ItineraryItem] {
        items.sorted { a, b in
            switch (a.isTimed, b.isTimed) {
            case (true, true):
                if a.startTimeMinutes != b.startTimeMinutes {
                    return a.startTimeMinutes < b.startTimeMinutes
                }
                return a.sortOrder < b.sortOrder
            case (true, false):
                return true
            case (false, true):
                return false
            case (false, false):
                if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
                return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
            }
        }
    }

    /// Total planned cost for a single day.
    static func dayCost(_ day: TripDay) -> Double {
        day.items.reduce(0) { $0 + $1.cost }
    }

    // MARK: Countdown classification

    enum Countdown: Equatable {
        case upcoming(days: Int)        // days until departure (>= 1, today departing -> 0 handled by onTrip)
        case onTrip(day: Int, of: Int)  // 1-based current day of total
        case completed(daysAgo: Int)

        var phase: TripPhase {
            switch self {
            case .upcoming: return .upcoming
            case .onTrip: return .inProgress
            case .completed: return .past
            }
        }
    }

    /// Classify a trip relative to `now`.
    static func countdown(start: Date,
                          end: Date,
                          now: Date = Date(),
                          calendar: Calendar = ItineraryEngine.calendar) -> Countdown {
        let today = calendar.startOfDay(for: now)
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: max(end, start))
        let total = durationDays(start: s, end: e, calendar: calendar)

        if today < s {
            let comps = calendar.dateComponents([.day], from: today, to: s)
            return .upcoming(days: max(1, comps.day ?? 1))
        } else if today > e {
            let comps = calendar.dateComponents([.day], from: e, to: today)
            return .completed(daysAgo: max(1, comps.day ?? 1))
        } else {
            let comps = calendar.dateComponents([.day], from: s, to: today)
            let dayIndex = (comps.day ?? 0) + 1
            return .onTrip(day: min(dayIndex, total), of: total)
        }
    }

    /// Human-readable short countdown label.
    static func countdownLabel(_ c: Countdown) -> String {
        switch c {
        case .upcoming(let days):
            return days == 1 ? "Tomorrow" : "In \(days) days"
        case .onTrip(let day, let of):
            return "Day \(day) of \(of)"
        case .completed(let daysAgo):
            if daysAgo == 1 { return "Yesterday" }
            if daysAgo < 30 { return "\(daysAgo) days ago" }
            if daysAgo < 60 { return "Last month" }
            return "\(daysAgo / 30) months ago"
        }
    }

    // MARK: Time formatting

    /// Format minutes-from-midnight to a localized time, honoring 24h preference.
    static func timeLabel(minutes: Int, use24h: Bool) -> String {
        guard minutes >= 0 else { return "Anytime" }
        let clamped = min(max(minutes, 0), 24 * 60 - 1)
        let h = clamped / 60
        let m = clamped % 60
        if use24h {
            return String(format: "%02d:%02d", h, m)
        } else {
            let period = h < 12 ? "AM" : "PM"
            var hour12 = h % 12
            if hour12 == 0 { hour12 = 12 }
            return String(format: "%d:%02d %@", hour12, m, period)
        }
    }

    static func durationLabel(_ minutes: Int) -> String {
        guard minutes > 0 else { return "" }
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
