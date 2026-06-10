import SwiftUI
import SwiftData

struct TimelineView: View {
    @Query(sort: \GratitudeDay.date, order: .reverse) private var days: [GratitudeDay]
    @State private var monthAnchor = Calendar.current.startOfDay(for: .now)
    @State private var detailDay: GratitudeDay?

    private var calendar: Calendar { .current }

    private var monthDays: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) - calendar.firstWeekday
        let leading = (firstWeekday + 7) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        var result: [Date] = []
        if let start = calendar.date(byAdding: .day, value: -leading, to: interval.start) {
            for i in 0..<(leading + daysInMonth) {
                if let d = calendar.date(byAdding: .day, value: i, to: start) { result.append(d) }
            }
        }
        return result
    }

    private func entry(for date: Date) -> GratitudeDay? {
        let key = PlentyEngine.dayKey(date)
        return days.first { $0.dayKey == key }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if days.filter({ $0.hasAnyContent }).isEmpty {
                    EmptyStateView(icon: "calendar",
                                   title: "Your journal is empty",
                                   message: "Complete a morning or evening ritual and it will appear here, colored by your mood.")
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            calendarCard
                            recentList
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Journal")
            .sheet(item: $detailDay) { DayDetailView(day: $0) }
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 14) {
            HStack {
                Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Spacer()
                Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                    .font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
                    .disabled(isCurrentMonth)
            }
            .foregroundStyle(Brand.text)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym).font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                ForEach(monthDays, id: \.self) { date in
                    dayCell(date)
                }
            }
        }
        .glassCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: monthAnchor, toGranularity: .month)
        let e = entry(for: date)
        let mood = Mood(rawValue: e?.mood ?? 0)
        let isToday = calendar.isDateInToday(date)
        return Button {
            if let e, e.hasAnyContent { detailDay = e }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(Brand.mono(13, weight: isToday ? .bold : .regular))
                .foregroundStyle(inMonth ? (mood != nil ? .white : Brand.text) : Brand.text3.opacity(0.4))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    Circle().fill(mood?.color ?? (e?.hasAnyContent == true ? Brand.live.opacity(0.5) : .clear))
                )
                .overlay(
                    Circle().strokeBorder(isToday ? Brand.text : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(!(e?.hasAnyContent ?? false))
        .opacity(inMonth ? 1 : 0.4)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))\(mood != nil ? ", mood \(mood!.label)" : "")")
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Recent entries")
            ForEach(days.filter { $0.hasAnyContent }.prefix(20)) { day in
                Button { detailDay = day } label: { entryRow(day) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func entryRow(_ day: GratitudeDay) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(Mood(rawValue: day.mood)?.emoji ?? "🌱").font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(day.date.formatted(.dateTime.weekday().month().day()))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Brand.text)
                let snippet = (day.filledGratitudes.first ?? day.filledWins.first ?? day.dailyIntention)
                Text(snippet.isEmpty ? "—" : snippet)
                    .font(.subheadline).foregroundStyle(Brand.text2).lineLimit(2)
            }
            Spacer()
            VStack(spacing: 3) {
                if day.morningDone { Image(systemName: "sunrise.fill").font(.caption2).foregroundStyle(Brand.warn) }
                if day.eveningDone { Image(systemName: "moon.fill").font(.caption2).foregroundStyle(Brand.info) }
            }
        }
        .glassCard(padding: 14)
    }

    private var weekdaySymbols: [String] {
        let syms = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(syms[first...] + syms[..<first])
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(monthAnchor, equalTo: .now, toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            if delta > 0 && d > Date.now { return }
            withAnimation(Brand.ease()) { monthAnchor = d }
        }
    }
}
