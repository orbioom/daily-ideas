import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Habit.order) private var habits: [Habit]
    @Query private var allEntries: [HabitEntry]
    @AppStorage("anchor.weekStart") private var weekStartRaw = "sunday"

    @State private var displayMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: .now)
        return cal.date(from: comps) ?? .now
    }()
    @State private var selectedHabitID: UUID? = nil
    @State private var selectedDay: Date? = nil
    @State private var showDaySheet = false

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = weekStartRaw == "monday" ? 2 : 1
        return cal
    }

    private var selectedHabit: Habit? {
        guard let id = selectedHabitID else { return nil }
        return habits.first { $0.id == id }
    }

    private var activeHabits: [Habit] {
        habits.filter { !$0.archived }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 20) {
                        habitFilterPicker
                        monthNavigator
                        weekdayHeader
                        monthGrid
                            .padding(.horizontal, 16)

                        if activeHabits.isEmpty {
                            EmptyStateView(
                                icon: "calendar.badge.plus",
                                title: "No Habits",
                                message: "Add habits in the Habits tab to see your calendar view."
                            )
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Calendar")
            .sheet(isPresented: $showDaySheet) {
                if let day = selectedDay {
                    DayDetailSheet(
                        day: day,
                        habits: activeHabits,
                        entries: allEntries,
                        calendar: calendar
                    )
                    .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: - Habit filter picker

    private var habitFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All Habits", id: nil)
                ForEach(activeHabits) { habit in
                    filterChip(label: habit.name, id: habit.id, color: Color(hex: habit.colorHex))
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(label: String, id: UUID?, color: Color? = nil) -> some View {
        let isSelected = selectedHabitID == id
        return Button {
            selectedHabitID = id
            Haptics.selection()
        } label: {
            HStack(spacing: 4) {
                if let c = color {
                    Circle().fill(c).frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(isSelected ? .white : Brand.text2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected
                    ? (color ?? Brand.live)
                    : Color.clear,
                in: Capsule()
            )
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Brand.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected ? "selected" : "not selected")
    }

    // MARK: - Month navigator

    private var monthNavigator: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.text2)
                    .padding(8)
            }
            .accessibilityLabel("Previous month")

            Spacer()

            Text(Format.monthYear.string(from: displayMonth))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Brand.text2)
                    .padding(8)
            }
            .accessibilityLabel("Next month")
        }
        .padding(.horizontal, 16)
    }

    private func changeMonth(by delta: Int) {
        guard let next = calendar.date(byAdding: .month, value: delta, to: displayMonth) else { return }
        displayMonth = next
        Haptics.selection()
    }

    // MARK: - Weekday header

    private var weekdayHeader: some View {
        let symbols = calendar.veryShortWeekdaySymbols
        let ordered = orderedWeekdaySymbols(symbols)
        return HStack(spacing: 0) {
            ForEach(ordered, id: \.self) { sym in
                Text(sym)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
    }

    private func orderedWeekdaySymbols(_ symbols: [String]) -> [String] {
        let first = calendar.firstWeekday - 1
        guard first > 0 && first < symbols.count else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }

    // MARK: - Month grid

    private var monthGrid: some View {
        let days = daysInMonth()
        let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

        return LazyVGrid(columns: cols, spacing: 4) {
            ForEach(days, id: \.offset) { item in
                if let date = item.date {
                    CalendarDayCell(
                        date: date,
                        intensity: intensity(for: date),
                        color: cellColor,
                        isToday: calendar.isDateInToday(date),
                        isSelected: selectedDay.map { calendar.startOfDay(for: $0) == calendar.startOfDay(for: date) } ?? false
                    )
                    .onTapGesture {
                        selectedDay = date
                        showDaySheet = true
                        Haptics.tap()
                    }
                } else {
                    Color.clear.frame(height: 40)
                }
            }
        }
    }

    private var cellColor: Color {
        if let h = selectedHabit { return Color(hex: h.colorHex) }
        return Brand.live
    }

    private func intensity(for date: Date) -> Double {
        let today = calendar.startOfDay(for: .now)
        guard date <= today else { return 0 }

        if let habit = selectedHabit {
            guard StreakEngine.isScheduled(habit, on: date, calendar: calendar) else { return 0 }
            let cnt = StreakEngine.count(for: habit, on: date, entries: allEntries, calendar: calendar)
            if cnt == 0 { return 0 }
            let target = habit.dailyTarget
            return target > 0 ? min(Double(cnt) / Double(target), 1.0) : 1.0
        }

        let scheduled = activeHabits.filter {
            StreakEngine.isScheduled($0, on: date, calendar: calendar)
        }
        guard !scheduled.isEmpty else { return 0 }
        let done = scheduled.filter {
            StreakEngine.isComplete($0, on: date, entries: allEntries, calendar: calendar)
        }.count
        return Double(done) / Double(scheduled.count)
    }

    // MARK: - Date helpers

    private struct DayItem {
        let offset: Int
        let date: Date?
    }

    private func daysInMonth() -> [DayItem] {
        var comps = calendar.dateComponents([.year, .month], from: displayMonth)
        comps.day = 1
        guard let firstDay = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return []
        }

        let weekdayOfFirst = calendar.component(.weekday, from: firstDay)
        let firstWeekday = calendar.firstWeekday
        let leadingBlanks = (weekdayOfFirst - firstWeekday + 7) % 7

        var items: [DayItem] = []
        var offset = 0

        for _ in 0..<leadingBlanks {
            items.append(DayItem(offset: offset, date: nil))
            offset += 1
        }

        for day in range {
            var dc = comps
            dc.day = day
            let date = calendar.date(from: dc).map { calendar.startOfDay(for: $0) }
            items.append(DayItem(offset: offset, date: date))
            offset += 1
        }

        return items
    }
}

// MARK: - Calendar Day Cell

private struct CalendarDayCell: View {
    let date: Date
    let intensity: Double
    let color: Color
    let isToday: Bool
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(cellFill)
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isToday ? Brand.live : Color.clear, lineWidth: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isSelected ? Brand.text.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )

            Text(Format.dayOfMonth.string(from: date))
                .font(.caption.weight(isToday ? .bold : .regular))
                .foregroundStyle(intensity > 0.5 ? .white : (isToday ? Brand.live : Brand.text2))
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var cellFill: Color {
        if intensity <= 0 { return color.opacity(0.06) }
        return color.opacity(0.2 + intensity * 0.75)
    }

    private var accessibilityLabel: String {
        let dayStr = Format.shortDate.string(from: date)
        let pct = Int(intensity * 100)
        return "\(dayStr), \(pct)% complete"
    }
}

// MARK: - Day Detail Sheet

private struct DayDetailSheet: View {
    let day: Date
    let habits: [Habit]
    let entries: [HabitEntry]
    let calendar: Calendar
    @Environment(\.dismiss) private var dismiss

    private var scheduledHabits: [Habit] {
        habits.filter { StreakEngine.isScheduled($0, on: day, calendar: calendar) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                if scheduledHabits.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "Nothing Scheduled",
                        message: "No habits were set for this day."
                    )
                } else {
                    List {
                        Section {
                            ForEach(scheduledHabits) { habit in
                                DayHabitRow(habit: habit, entries: entries, day: day, calendar: calendar)
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            Eyebrow(text: Format.dayFull.string(from: day))
                                .padding(.leading, -4)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(Format.dayFull.string(from: day))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Brand.text)
                }
            }
        }
    }
}

private struct DayHabitRow: View {
    let habit: Habit
    let entries: [HabitEntry]
    let day: Date
    let calendar: Calendar

    private var isComplete: Bool {
        StreakEngine.isComplete(habit, on: day, entries: entries, calendar: calendar)
    }
    private var count: Int {
        StreakEngine.count(for: habit, on: day, entries: entries, calendar: calendar)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.colorHex).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: habit.symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: habit.colorHex))
                    .accessibilityHidden(true)
            }

            Text(habit.name)
                .font(.body)
                .foregroundStyle(Brand.text)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Brand.live)
                    .accessibilityLabel("Completed")
            } else if count > 0 {
                Text("\(count)/\(habit.dailyTarget)")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.warn)
                    .accessibilityLabel("Partial: \(count) of \(habit.dailyTarget)")
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(Brand.text3)
                    .accessibilityLabel("Not done")
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(habit.name): \(isComplete ? "complete" : count > 0 ? "partial" : "not done")")
    }
}
