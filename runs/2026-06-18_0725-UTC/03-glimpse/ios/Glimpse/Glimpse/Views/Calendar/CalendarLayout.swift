import Foundation

/// A grid cell: either a real date or a leading/trailing blank.
struct CalendarCell: Identifiable {
    let id: Int       // grid position
    let date: Date?
}

/// Computes the day cells for the month containing `monthDate`, padded with
/// blanks so the first day lands under the correct weekday column.
enum CalendarLayout {
    static func cells(for monthDate: Date, calendar: Calendar) -> [CalendarCell] {
        guard let interval = calendar.dateInterval(of: .month, for: monthDate) else { return [] }
        let firstOfMonth = interval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 0
        guard daysInMonth > 0 else { return [] }

        // Weekday of the first day (1...7), adjusted for the calendar's firstWeekday.
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leading = ((weekday - calendar.firstWeekday) + 7) % 7

        var cells: [CalendarCell] = []
        var position = 0
        for _ in 0..<leading {
            cells.append(CalendarCell(id: position, date: nil))
            position += 1
        }
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: firstOfMonth) {
                cells.append(CalendarCell(id: position, date: date))
            } else {
                cells.append(CalendarCell(id: position, date: nil))
            }
            position += 1
        }
        // Pad to a full final week.
        while cells.count % 7 != 0 {
            cells.append(CalendarCell(id: position, date: nil))
            position += 1
        }
        return cells
    }
}
