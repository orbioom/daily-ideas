import SwiftUI
import SwiftData

/// A month grid of day cells with markers on days that have bill occurrences.
/// Tap a day to see the bills due that day; navigate months with the arrows.
struct CalendarView: View {
    @Query(sort: \Bill.dueDate) private var bills: [Bill]
    @AppStorage("currencyCode") private var currencyCode = "USD"
    @AppStorage("weekStartsMonday") private var weekStartsMonday = false

    @State private var visibleMonth: Date = .now
    @State private var selectedDay: Date?

    private var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = weekStartsMonday ? 2 : 1
        return c
    }

    private var occurrences: [BillOccurrence] {
        BillEngine.occurrences(in: visibleMonth, bills: bills)
    }

    /// Occurrences keyed by start-of-day.
    private var byDay: [Date: [BillOccurrence]] {
        Dictionary(grouping: occurrences) { cal.startOfDay(for: $0.date) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        monthHeader
                        Card {
                            VStack(spacing: 10) {
                                weekdayHeader
                                grid
                            }
                        }
                        selectedDaySheet
                    }
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                }
            }
            .navigationTitle("Calendar")
        }
    }

    private var monthTitle: String {
        visibleMonth.formatted(.dateTime.month(.wide).year())
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.accent).frame(width: 40, height: 36)
            }
            .accessibilityLabel("Previous month")
            Spacer()
            Text(monthTitle).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
            Spacer()
            Button {
                shiftMonth(1)
            } label: {
                Image(systemName: "chevron.right").font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.accent).frame(width: 40, height: 36)
            }
            .accessibilityLabel("Next month")
        }
    }

    private var weekdaySymbols: [String] {
        let base = cal.shortWeekdaySymbols // Sunday-first
        let start = cal.firstWeekday - 1   // 0-based
        guard base.count == 7 else { return base }
        return Array(base[start...] + base[..<start])
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, s in
                Text(s.prefix(1))
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.inkFaint)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// The days to render: leading blanks for alignment, then each day of month.
    private var gridDays: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstOfMonth = interval.start
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth) // 1...7
        let leadingBlanks = (weekdayOfFirst - cal.firstWeekday + 7) % 7
        let dayRange = cal.range(of: .day, in: .month, for: firstOfMonth) ?? 1..<29

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in dayRange {
            if let d = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                cells.append(d)
            }
        }
        // Pad trailing to complete the last week.
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
            ForEach(Array(gridDays.enumerated()), id: \.offset) { _, maybeDay in
                if let day = maybeDay {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let key = cal.startOfDay(for: day)
        let items = byDay[key] ?? []
        let isToday = cal.isDateInToday(day)
        let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
        let dayNum = cal.component(.day, from: day)

        return Button {
            Haptics.tap()
            // Tapping the selected day again clears it; otherwise select this day.
            selectedDay = isSelected ? nil : day
        } label: {
            VStack(spacing: 3) {
                Text("\(dayNum)")
                    .font(Theme.rounded(14, isToday ? .bold : .medium))
                    .foregroundStyle(isToday ? Theme.accent : Theme.ink)
                HStack(spacing: 2) {
                    ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, occ in
                        Circle()
                            .fill(occ.bill.category.color)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isSelected ? Theme.accentSoft : (items.isEmpty ? Color.clear : Theme.surfaceAlt))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(isToday ? Theme.accent : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Fmt.mediumDate(day))\(items.isEmpty ? ", no bills" : ", \(items.count) bill\(items.count == 1 ? "" : "s") due")")
    }

    @ViewBuilder
    private var selectedDaySheet: some View {
        if let day = selectedDay {
            let items = (byDay[cal.startOfDay(for: day)] ?? []).sorted { $0.amount > $1.amount }
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text(Fmt.mediumDate(day))
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    if items.isEmpty {
                        Text("No bills due this day.")
                            .font(Theme.rounded(14, .regular)).foregroundStyle(Theme.inkSoft)
                    } else {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, occ in
                            HStack(spacing: 12) {
                                CategoryIcon(category: occ.bill.category, size: 32)
                                Text(occ.bill.name)
                                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Spacer()
                                Text(Fmt.money(occ.amount, code: currencyCode))
                                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                            }
                            .accessibilityElement(children: .combine)
                            if idx < items.count - 1 { Divider().background(Theme.hairline) }
                        }
                        let total = items.reduce(Decimal(0)) { $0 + $1.amount }
                        Divider().background(Theme.hairline)
                        HStack {
                            Text("Total").font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                            Spacer()
                            Text(Fmt.money(total, code: currencyCode))
                                .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.accent)
                        }
                    }
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: visibleMonth) {
            visibleMonth = d
            selectedDay = nil
            Haptics.soft()
        }
    }
}
