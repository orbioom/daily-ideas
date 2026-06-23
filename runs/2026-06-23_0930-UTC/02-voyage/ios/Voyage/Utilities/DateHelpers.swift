import Foundation

extension Date {
    /// A short, human relative description of when this date is due.
    func dueDescription(relativeTo now: Date = .now, calendar: Calendar = .current) -> String {
        let startNow = calendar.startOfDay(for: now)
        let startDue = calendar.startOfDay(for: self)
        let days = calendar.dateComponents([.day], from: startNow, to: startDue).day ?? 0
        if days <= 0 { return "Due now" }
        if days == 1 { return "Tomorrow" }
        if days < 7 { return "In \(days) days" }
        if days < 30 {
            let weeks = days / 7
            return weeks == 1 ? "In 1 week" : "In \(weeks) weeks"
        }
        let months = max(1, days / 30)
        return months == 1 ? "In 1 month" : "In \(months) months"
    }

    /// Whether this date is due on or before `now`.
    func isDue(by now: Date = .now) -> Bool {
        self <= now
    }
}
