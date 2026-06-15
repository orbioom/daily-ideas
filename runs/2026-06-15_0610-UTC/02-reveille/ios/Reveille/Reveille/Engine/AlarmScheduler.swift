import Foundation

/// Computes the next fire `Date` for an alarm from its time-of-day plus repeat-weekday set.
/// DST/leap-safe because all arithmetic goes through `Calendar`/`DateComponents` rather than
/// raw `TimeInterval` math. Pure and `Sendable`; no UI or persistence dependencies.
enum AlarmScheduler {

    /// The next time this alarm will ring at or after `reference`. Returns `nil` only if the
    /// alarm is disabled (callers treat that as "no upcoming fire").
    static func nextFireDate(hour: Int,
                             minute: Int,
                             repeatDays: [Int],
                             isEnabled: Bool,
                             reference: Date = Date(),
                             calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        let h = min(23, max(0, hour))
        let m = min(59, max(0, minute))
        let valid = Set(repeatDays.filter { (1...7).contains($0) })

        if valid.isEmpty {
            // One-shot: today at h:m if still in the future, else tomorrow.
            return oneShotDate(hour: h, minute: m, reference: reference, calendar: calendar)
        }

        // Repeating: scan the next 8 days (covers wrap-around) for the first matching weekday
        // whose h:m is at or after `reference`.
        for offset in 0..<8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: reference) else { continue }
            var comps = calendar.dateComponents([.year, .month, .day], from: day)
            comps.hour = h
            comps.minute = m
            comps.second = 0
            guard let candidate = calendar.date(from: comps) else { continue }
            let weekday = calendar.component(.weekday, from: candidate)
            guard valid.contains(weekday) else { continue }
            if candidate >= reference { return candidate }
        }
        return nil
    }

    /// Convenience overload taking an `Alarm`.
    static func nextFireDate(for alarm: Alarm,
                             reference: Date = Date(),
                             calendar: Calendar = .current) -> Date? {
        nextFireDate(hour: alarm.hour,
                     minute: alarm.minute,
                     repeatDays: alarm.repeatDays,
                     isEnabled: alarm.isEnabled,
                     reference: reference,
                     calendar: calendar)
    }

    private static func oneShotDate(hour: Int,
                                    minute: Int,
                                    reference: Date,
                                    calendar: Calendar) -> Date? {
        var comps = calendar.dateComponents([.year, .month, .day], from: reference)
        comps.hour = hour
        comps.minute = minute
        comps.second = 0
        guard let today = calendar.date(from: comps) else { return nil }
        if today > reference { return today }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    /// Sort alarms by their next occurrence; alarms with no upcoming fire (disabled) sort last,
    /// then by creation order so the list is stable.
    static func sortedByNextFire(_ alarms: [Alarm], reference: Date = Date()) -> [Alarm] {
        alarms.sorted { a, b in
            let na = nextFireDate(for: a, reference: reference)
            let nb = nextFireDate(for: b, reference: reference)
            switch (na, nb) {
            case let (.some(x), .some(y)): return x < y
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none): return a.createdAt < b.createdAt
            }
        }
    }

    /// The soonest upcoming fire across all alarms, if any.
    static func soonestFire(_ alarms: [Alarm], reference: Date = Date()) -> (alarm: Alarm, date: Date)? {
        var best: (alarm: Alarm, date: Date)?
        for alarm in alarms {
            guard let date = nextFireDate(for: alarm, reference: reference) else { continue }
            if let current = best {
                if date < current.date { best = (alarm, date) }
            } else {
                best = (alarm, date)
            }
        }
        return best
    }

    // MARK: Labels

    /// "rings in 7h 12m" style countdown. Guards against negative/zero intervals.
    static func countdownLabel(to date: Date, from reference: Date = Date()) -> String {
        let seconds = max(0, Int(date.timeIntervalSince(reference)))
        if seconds < 60 { return "less than a minute" }
        let totalMinutes = seconds / 60
        let days = totalMinutes / (60 * 24)
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    /// "Rings in 7h 12m" prefixed form for headers.
    static func ringsInLabel(to date: Date, from reference: Date = Date()) -> String {
        "Rings in \(countdownLabel(to: date, from: reference))"
    }

    /// Short weekday repeat summary, e.g. "Weekdays", "Every day", "Sun, Sat", or "Once".
    static func repeatSummary(_ repeatDays: [Int]) -> String {
        let days = Set(repeatDays.filter { (1...7).contains($0) })
        if days.isEmpty { return "Once" }
        if days == Set(1...7) { return "Every day" }
        if days == Set([2, 3, 4, 5, 6]) { return "Weekdays" }
        if days == Set([1, 7]) { return "Weekends" }
        let names = days.sorted().compactMap { Weekday(rawValue: $0)?.short }
        return names.joined(separator: ", ")
    }
}

/// Weekday helper using `Calendar`'s 1 = Sunday … 7 = Saturday numbering.
enum Weekday: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var short: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var letter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    /// Monday-first ordering for the weekday picker (M T W T F S S).
    static var pickerOrder: [Weekday] {
        [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}
