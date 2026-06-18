import SwiftUI

/// A month heatmap of play activity. Filled tiles = days at least one word was found;
/// stronger tiles = Genius reached.
struct StreakCalendarView: View {
    let results: [DailyResult]

    private let cal = Calendar(identifier: .gregorian)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var resultByKey: [String: DailyResult] {
        Dictionary(results.map { ($0.dateKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    /// Days of the current month, padded with leading blanks for weekday alignment.
    private var monthDays: [Date?] {
        let now = Date()
        guard let interval = cal.dateInterval(of: .month, for: now),
              let range = cal.range(of: .day, in: .month, for: now) else { return [] }
        let firstWeekday = cal.component(.weekday, from: interval.start) // 1 = Sunday
        let leading = firstWeekday - 1
        var days: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = cal.date(byAdding: .day, value: day - 1, to: interval.start) {
                days.append(date)
            }
        }
        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(monthTitle)
                    .font(Theme.rounded(17, .bold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { d in
                    Text(d)
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    dayCell(date)
                }
            }

            legend
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let key = DateKey.key(for: date)
            let result = resultByKey[key]
            let played = (result?.wordsFound ?? 0) > 0
            let genius = result?.reachedGenius ?? false
            let isToday = cal.isDateInToday(date)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(fill(played: played, genius: genius))
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isToday ? Theme.accentDeep : Color.clear, lineWidth: 2)
                )
                .overlay(
                    Text("\(cal.component(.day, from: date))")
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(played ? Color.white : Theme.inkSoft)
                )
                .frame(height: 34)
                .accessibilityLabel(accessibilityLabel(date: date, played: played, genius: genius))
        } else {
            Color.clear.frame(height: 34)
        }
    }

    private func fill(played: Bool, genius: Bool) -> Color {
        if genius { return Theme.accentDeep }
        if played { return Theme.accent.opacity(0.6) }
        return Theme.surfaceAlt
    }

    private func accessibilityLabel(date: Date, played: Bool, genius: Bool) -> String {
        let day = cal.component(.day, from: date)
        if genius { return "Day \(day), reached Genius" }
        if played { return "Day \(day), played" }
        return "Day \(day), not played"
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendItem(color: Theme.surfaceAlt, label: "None")
            legendItem(color: Theme.accent.opacity(0.6), label: "Played")
            legendItem(color: Theme.accentDeep, label: "Genius")
        }
        .font(Theme.rounded(12))
        .foregroundStyle(Theme.inkSoft)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 14, height: 14)
            Text(label)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}
