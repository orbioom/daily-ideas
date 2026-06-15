import SwiftUI

/// A compact 5-week calendar showing which days this tracker was logged, tinted by relative value.
/// Tapping a logged day opens its Day Detail.
struct LoggedCalendarCard: View {
    let tracker: Tracker
    var onSelectDay: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var loggedValues: [Date: Double] {
        var map: [Date: Double] = [:]
        for e in tracker.sortedEntries { map[DayMath.startOfDay(e.date)] = e.value }
        return map
    }

    /// The last 35 days, oldest first, aligned so weeks read left-to-right.
    private var days: [Date] { DayMath.recentDays(35) }

    private var bounds: (min: Double, max: Double) {
        let vals = loggedValues.values
        guard let lo = vals.min(), let hi = vals.max() else { return (0, 1) }
        return (lo, hi)
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Last 5 weeks")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(days, id: \.timeIntervalSince1970) { day in
                        cell(for: day)
                    }
                }

                HStack(spacing: 8) {
                    legendSwatch(tracker.color.opacity(0.25))
                    Text("low")
                        .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    legendSwatch(tracker.color)
                    Text("high")
                        .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                    Spacer()
                    Text("Tap a day to edit")
                        .font(Theme.rounded(11)).foregroundStyle(Theme.inkFaint)
                }
                .accessibilityHidden(true)
            }
        }
    }

    private func cell(for day: Date) -> some View {
        let value = loggedValues[day]
        let isLogged = value != nil
        let intensity = intensityFor(value)
        return Button {
            if isLogged { onSelectDay(day) }
        } label: {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isLogged ? tracker.color.opacity(0.25 + 0.75 * intensity) : Theme.surfaceAlt)
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: isLogged ? 0 : 1)
                )
        }
        .disabled(!isLogged)
        .accessibilityLabel(day.shortDayLabel)
        .accessibilityValue(isLogged ? "Logged" : "Not logged")
    }

    private func intensityFor(_ value: Double?) -> Double {
        guard let value else { return 0 }
        let (lo, hi) = bounds
        guard hi > lo else { return 0.8 }
        return min(1, max(0, (value - lo) / (hi - lo)))
    }

    private func legendSwatch(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 14, height: 14)
    }
}
