import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @AppStorage("weekStartsMonday") private var weekStartsMonday = false

    @State private var month: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: Date?
    @State private var editing: JournalEntry?

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = weekStartsMonday ? 2 : 1
        return c
    }

    /// startOfDay → entries that day
    private var byDay: [Date: [JournalEntry]] {
        Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
    }

    private var selectedEntries: [JournalEntry] {
        guard let day = selectedDay else { return [] }
        return (byDay[calendar.startOfDay(for: day)] ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        monthHeader
                        weekdayHeader
                        monthGrid
                        if let day = selectedDay {
                            daySection(day)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .sheet(item: $editing) { EntryEditorView(entry: $0) }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(-1)
            } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(Format.monthYear.string(from: month))
                .font(.title3.weight(.semibold))
                .foregroundStyle(Brand.text)
            Spacer()
            Button {
                shiftMonth(1)
            } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
        }
        .padding(.horizontal, 4)
    }

    private var weekdayHeader: some View {
        let symbols = orderedWeekdaySymbols()
        return HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = monthDays()
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let key = calendar.startOfDay(for: day)
        let items = byDay[key] ?? []
        let isToday = calendar.isDateInToday(day)
        let isSelected = selectedDay.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        let moodColor = dominantMoodColor(items)

        return Button {
            withAnimation(Brand.ease(0.25)) {
                selectedDay = isSelected ? nil : day
            }
            Haptics.selection()
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline)
                    .foregroundStyle(isToday ? Color.accentColor : Brand.text)
                Circle()
                    .fill(items.isEmpty ? Color.clear : (moodColor ?? Color.accentColor))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isToday ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessLabel(day, count: items.count))
    }

    private func daySection(_ day: Date) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Format.dayFull.string(from: day))
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Spacer()
                Button {
                    let entry = JournalEntry(date: noonOn(day))
                    context.insert(entry)
                    editing = entry
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .accessibilityLabel("Add entry on this day")
            }
            if selectedEntries.isEmpty {
                Text("No entries this day.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(selectedEntries) { entry in
                    Button { editing = entry } label: {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private var isCurrentMonth: Bool {
        calendar.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        if delta > 0 && isCurrentMonth { return }
        if let m = calendar.date(byAdding: .month, value: delta, to: month) {
            withAnimation(Brand.ease(0.3)) { month = m }
        }
    }

    private func noonOn(_ day: Date) -> Date {
        calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    private func dominantMoodColor(_ items: [JournalEntry]) -> Color? {
        let rated = items.filter { $0.mood > 0 }
        guard !rated.isEmpty else { return nil }
        let avg = Double(rated.reduce(0) { $0 + $1.mood }) / Double(rated.count)
        let rounded = max(1, min(5, Int(avg.rounded())))
        return Color(hex: Mood(rawValue: rounded)?.colorHex ?? 0x7CA68F)
    }

    private func orderedWeekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        let first = calendar.firstWeekday - 1
        guard first < symbols.count else { return symbols }
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Day cells for the month grid, padded with nil leading blanks.
    private func monthDays() -> [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = interval.start
        let weekday = calendar.component(.weekday, from: firstDay)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<2
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: firstDay) {
                cells.append(date)
            }
        }
        return cells
    }

    private func accessLabel(_ day: Date, count: Int) -> String {
        let base = Format.dayFull.string(from: day)
        if count == 0 { return "\(base), no entries" }
        return "\(base), \(count) \(count == 1 ? "entry" : "entries")"
    }
}
