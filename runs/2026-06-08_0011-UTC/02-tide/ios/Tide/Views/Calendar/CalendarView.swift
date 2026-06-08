import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \MoodEntry.date, order: .reverse) private var entries: [MoodEntry]
    @State private var month: Date = Calendar.current.startOfDay(for: .now)
    @State private var selectedDay: Date?

    private let cal = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        monthHeader
                        weekdayHeader
                        grid
                        legend
                        if let day = selectedDay {
                            dayDetail(day)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Calendar")
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous month")
            Spacer()
            Text(Format.monthYear.string(from: month))
                .font(.title3.weight(.semibold)).foregroundStyle(Brand.text)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next month")
                .disabled(isCurrentMonth)
        }
        .foregroundStyle(Brand.text)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(shortWeekdaySymbols, id: \.self) { s in
                Text(s).font(.caption2).foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(daysInGrid, id: \.self) { day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let dayEntries = entries.filter { cal.isDate($0.date, inSameDayAs: day) }
        let avg = dayEntries.isEmpty ? 0 : dayEntries.map { Double($0.mood) }.reduce(0, +) / Double(dayEntries.count)
        let hasData = !dayEntries.isEmpty
        let isSel = selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
        return Button {
            selectedDay = isSel ? nil : day
            Haptics.selection()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(hasData ? Mood.color(Int(avg.rounded())).opacity(0.9) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(isSel ? Brand.text : Brand.hairline, lineWidth: isSel ? 2 : 1)
                    )
                Text("\(cal.component(.day, from: day))")
                    .font(Brand.mono(13))
                    .foregroundStyle(hasData ? .white : Brand.text2)
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(cal.component(.day, from: day)). \(hasData ? Mood.label(Int(avg.rounded())) : "No entry")")
    }

    private func dayDetail(_ day: Date) -> some View {
        let dayEntries = entries.filter { cal.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(Format.dayTime.string(from: day).components(separatedBy: " · ").first ?? "")
                    .font(.headline).foregroundStyle(Brand.text)
                if dayEntries.isEmpty {
                    Text("No check-ins this day.").font(.subheadline).foregroundStyle(Brand.text2)
                } else {
                    ForEach(dayEntries) { e in
                        HStack(spacing: 10) {
                            Image(systemName: Mood.symbol(e.mood)).foregroundStyle(Mood.color(e.mood))
                            Text(Mood.label(e.mood)).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Text(Format.time.string(from: e.date)).font(Brand.mono(12)).foregroundStyle(Brand.text3)
                        }
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { l in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3).fill(Mood.color(l)).frame(width: 12, height: 12)
                    Text(Mood.label(l)).font(.caption2).foregroundStyle(Brand.text2)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: helpers
    private var shortWeekdaySymbols: [String] {
        let symbols = cal.shortStandaloneWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var daysInGrid: [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: month) else { return [] }
        let firstDay = interval.start
        let weekday = cal.component(.weekday, from: firstDay)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        let dayCount = cal.range(of: .day, in: .month, for: month)?.count ?? 30
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<dayCount {
            cells.append(cal.date(byAdding: .day, value: d, to: firstDay))
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private var isCurrentMonth: Bool {
        cal.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private func shift(_ by: Int) {
        if let m = cal.date(byAdding: .month, value: by, to: month) {
            if by > 0 && cal.compare(m, to: .now, toGranularity: .month) == .orderedDescending { return }
            month = m; selectedDay = nil
        }
    }
}
