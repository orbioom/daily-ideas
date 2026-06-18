import SwiftUI

/// A calendar month grid that marks days with a daily win.
struct MonthGrid: View {
    let monthOffset: Int
    let winKeys: Set<Int>
    let calendar: Calendar

    private struct Day: Identifiable {
        let id = UUID()
        let date: Date?     // nil = leading/trailing blank
    }

    private var days: [Day] {
        guard let base = calendar.date(byAdding: .month, value: monthOffset, to: Date()),
              let monthInterval = calendar.dateInterval(of: .month, for: base) else {
            return []
        }
        let firstOfMonth = monthInterval.start
        let comps = calendar.dateComponents([.year, .month], from: firstOfMonth)
        guard let range = calendar.range(of: .day, in: .month, for: firstOfMonth),
              let realFirst = calendar.date(from: comps) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: realFirst)
        // Leading blanks before the 1st, respecting firstWeekday.
        var leading = (weekday - calendar.firstWeekday)
        if leading < 0 { leading += 7 }

        var result: [Day] = []
        for _ in 0..<leading { result.append(Day(date: nil)) }
        for dayNum in range {
            if let d = calendar.date(byAdding: .day, value: dayNum - 1, to: realFirst) {
                result.append(Day(date: d))
            }
        }
        // Trailing blanks to complete the final week row.
        while result.count % 7 != 0 { result.append(Day(date: nil)) }
        return result
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days) { day in
                dayCell(day)
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ day: Day) -> some View {
        if let date = day.date {
            let key = Format.dayKey(date, calendar: calendar)
            let won = winKeys.contains(key)
            let isToday = calendar.isDateInToday(date)
            let isFuture = date > Date()
            let dayNum = calendar.component(.day, from: date)

            ZStack {
                Circle()
                    .fill(won ? Theme.accent : Theme.surfaceSoft)
                    .opacity(isFuture ? 0.4 : 1)
                if isToday {
                    Circle().strokeBorder(Theme.gold, lineWidth: 2)
                }
                Text("\(dayNum)")
                    .font(Theme.rounded(13, won ? .bold : .medium))
                    .foregroundStyle(won ? Color.white : (isFuture ? Theme.inkFaint : Theme.ink))
            }
            .frame(height: 34)
            .accessibilityLabel("\(Format.shortDay.string(from: date))")
            .accessibilityValue(won ? "daily won" : (isToday ? "today" : "no daily win"))
        } else {
            Color.clear.frame(height: 34)
                .accessibilityHidden(true)
        }
    }
}
