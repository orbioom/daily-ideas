import Foundation

enum TimeFormat {
    /// "MM:SS" or "H:MM:SS" for live countdown / elapsed.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%02d:%02d", m, sec)
    }

    /// Human duration like "1h 25m" or "25m".
    static func duration(minutes: Int) -> String {
        let m = max(0, minutes)
        let h = m / 60
        let rem = m % 60
        if h > 0 && rem > 0 { return "\(h)h \(rem)m" }
        if h > 0 { return "\(h)h" }
        return "\(rem)m"
    }

    static func durationSeconds(_ seconds: Int) -> String {
        if seconds < 60 { return "\(max(0, seconds))s" }
        return duration(minutes: seconds / 60)
    }

    static func hourLabel(_ hour: Int) -> String {
        let h = ((hour % 24) + 24) % 24
        if h == 0 { return "12a" }
        if h == 12 { return "12p" }
        if h < 12 { return "\(h)a" }
        return "\(h - 12)p"
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    static func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date().startOfDay) ?? Date().startOfDay
    }
}
