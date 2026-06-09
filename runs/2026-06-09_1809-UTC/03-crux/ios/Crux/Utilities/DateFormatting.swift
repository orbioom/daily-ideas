import Foundation

/// Lightweight, locale-aware date formatting used across lists.
enum CruxDate {
    /// "Today", "Tomorrow", "Yesterday", or a medium weekday-style label.
    static func relativeDay(_ date: Date, now: Date = .now, calendar cal: Calendar = .current) -> String {
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.calendar = cal
        // Within the next week, use weekday names; otherwise a dated label.
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: date)).day ?? 0
        if days > 0 && days < 7 {
            f.dateFormat = "EEEE"
        } else {
            f.setLocalizedDateFormatFromTemplate("EEE d MMM")
        }
        return f.string(from: date)
    }

    /// Short time, e.g. "9:00 AM".
    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    /// Full medium date, e.g. "Jun 9, 2026".
    static func medium(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    /// True when the time component is something other than midnight (so we know
    /// whether to show a time alongside a date).
    static func hasMeaningfulTime(_ date: Date, calendar cal: Calendar = .current) -> Bool {
        let comps = cal.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) != 0 || (comps.minute ?? 0) != 0
    }
}
