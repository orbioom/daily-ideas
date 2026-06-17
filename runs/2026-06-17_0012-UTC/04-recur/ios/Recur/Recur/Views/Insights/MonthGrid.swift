import SwiftUI

/// A month grid with renewal dots per day. Tapping a day selects it.
struct MonthGrid: View {
    @Environment(\.colorScheme) private var scheme
    let monthDate: Date
    let calendar: Calendar
    let renewalsByDay: [Date: [UpcomingRenewal]]
    @Binding var selectedDay: Date?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 8) {
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(daySlots.enumerated()), id: \.offset) { _, slot in
                    if let day = slot {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 4) {
            ForEach(orderedWeekdaySymbols, id: \.self) { sym in
                Text(sym)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(RecurTheme.secondaryText(scheme))
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        guard symbols.count == 7 else { return symbols }
        let start = max(0, min(6, calendar.firstWeekday - 1))
        return Array(symbols[start...] + symbols[..<start])
    }

    // MARK: - Day slots

    /// Optional dates: nil for leading blanks, then each day of the month.
    private var daySlots: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))
        else { return [] }

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        // Number of leading blanks given the configured firstWeekday.
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7

        var slots: [Date?] = Array(repeating: nil, count: leading)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                slots.append(date)
            }
        }
        return slots
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let key = calendar.startOfDay(for: day)
        let items = renewalsByDay[key] ?? []
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let dayNumber = calendar.component(.day, from: day)

        Button {
            Haptics.selection()
            selectedDay = isSelected ? nil : day
        } label: {
            VStack(spacing: 3) {
                Text("\(dayNumber)")
                    .font(.subheadline)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(cellTextColor(isToday: isToday, isSelected: isSelected))
                HStack(spacing: 2) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                        Circle()
                            .fill(Color(hex: item.subscription.colorHex))
                            .frame(width: 5, height: 5)
                    }
                    if items.count > 3 {
                        Circle().fill(RecurTheme.secondaryText(scheme)).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cellBackground(isToday: isToday, isSelected: isSelected))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(day: day, items: items, isToday: isToday))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func cellTextColor(isToday: Bool, isSelected: Bool) -> Color {
        if isSelected { return .white }
        if isToday { return RecurTheme.violet }
        return RecurTheme.primaryText(scheme)
    }

    private func cellBackground(isToday: Bool, isSelected: Bool) -> Color {
        if isSelected { return RecurTheme.violet }
        if isToday { return RecurTheme.violetSoft }
        return Color.clear
    }

    private func accessibilityLabel(day: Date, items: [UpcomingRenewal], isToday: Bool) -> String {
        var parts = [DateText.medium(day)]
        if isToday { parts.append("today") }
        if items.isEmpty {
            parts.append("no renewals")
        } else {
            parts.append("\(items.count) renewal\(items.count == 1 ? "" : "s")")
        }
        return parts.joined(separator: ", ")
    }
}
