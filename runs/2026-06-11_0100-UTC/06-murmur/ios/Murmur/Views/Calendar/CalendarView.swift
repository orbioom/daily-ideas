import SwiftUI
import SwiftData
import Charts

struct MurmurCalendarView: View {
    @Query(sort: \VoiceEntry.date, order: .reverse) private var entries: [VoiceEntry]
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedEntry: VoiceEntry?

    private var calendar: Calendar { .current }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        return range.compactMap { day in calendar.date(byAdding: .day, value: day - 1, to: first) }
    }

    private var entriesForSelectedDate: [VoiceEntry] {
        entries.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { $0.date > $1.date }
    }

    private func entriesForDate(_ date: Date) -> [VoiceEntry] {
        entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private var moodChartData: [(String, Int)] {
        var counts: [Mood: Int] = [:]
        entries.forEach { counts[$0.mood, default: 0] += 1 }
        return Mood.allCases.compactMap { m in
            let c = counts[m, default: 0]
            return c > 0 ? (m.emoji + " " + m.label, c) : nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthPicker
                    calendarGrid
                    selectedDayEntries
                    moodChart
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Calendar")
            .sheet(item: $selectedEntry) { EntryDetailView(entry: $0) }
        }
    }

    private var monthPicker: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(MurmurTheme.accent)
            }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Spacer()
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(MurmurTheme.accent)
            }
        }
        .padding(.horizontal, 4)
    }

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                    Text(d)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let firstWeekday = (calendar.component(.weekday, from: daysInMonth.first ?? Date()) - 1 + 7) % 7
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(0..<firstWeekday, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(daysInMonth, id: \.self) { date in
                    dayCell(date: date)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func dayCell(date: Date) -> some View {
        let dayEntries = entriesForDate(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayNum = calendar.component(.day, from: date)
        let mood = dayEntries.last?.mood

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 2) {
                Text("\(dayNum)")
                    .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : isToday ? MurmurTheme.accent : .primary)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? MurmurTheme.accent : Color.clear)
                    .clipShape(Circle())

                if let m = mood {
                    Text(m.emoji)
                        .font(.system(size: 9))
                } else if !dayEntries.isEmpty {
                    Circle()
                        .fill(MurmurTheme.accent)
                        .frame(width: 4, height: 4)
                } else {
                    Color.clear.frame(height: 9)
                }
            }
            .frame(height: 48)
        }
        .buttonStyle(.plain)
    }

    private var selectedDayEntries: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selectedDateLabel)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            if entriesForSelectedDate.isEmpty {
                Text("No entries on this day.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                ForEach(entriesForSelectedDate) { entry in
                    Button { selectedEntry = entry } label: {
                        HStack(spacing: 12) {
                            Text(entry.mood.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.displayTitle)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                Text(entry.formattedDuration)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var moodChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mood Distribution")
                .font(.system(size: 15, weight: .bold, design: .rounded))

            if moodChartData.isEmpty {
                Text("Start recording to see mood trends.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                Chart(moodChartData, id: \.0) { item in
                    SectorMark(
                        angle: .value("Count", item.1),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(by: .value("Mood", item.0))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartLegend(position: .trailing)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    private var selectedDateLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) { return "Today" }
        if cal.isDateInYesterday(selectedDate) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: selectedDate)
    }
}
