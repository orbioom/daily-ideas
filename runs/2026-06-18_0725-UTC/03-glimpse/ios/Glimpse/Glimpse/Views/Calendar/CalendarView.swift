import SwiftUI
import SwiftData

/// Month grid: each logged day shows a thumbnail or a mood-colored dot; tap a
/// day to see its moment(s). Month navigation + capture rate.
struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \Moment.createdAt, order: .reverse) private var moments: [Moment]

    @State private var visibleMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDayKey: String?

    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = settings.weekStart.weekdayIndex
        return c
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// Moments grouped by day key for fast lookup.
    private var byDay: [String: [Moment]] {
        Dictionary(grouping: moments, by: { $0.dayKey })
    }

    private var monthGrid: [CalendarCell] {
        CalendarLayout.cells(for: visibleMonth, calendar: calendar)
    }

    private var captureRate: Double {
        let interval = calendar.dateInterval(of: .month, for: visibleMonth)
        guard let interval else { return 0 }
        let daysInMonth = calendar.range(of: .day, in: .month, for: visibleMonth)?.count ?? 30
        // Count distinct logged days within the month.
        var logged = 0
        var cursor = interval.start
        while cursor < interval.end {
            if byDay[DayKey.key(for: cursor)] != nil { logged += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return daysInMonth > 0 ? Double(logged) / Double(daysInMonth) : 0
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        guard symbols.count == 7, start >= 0, start < 7 else { return symbols }
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    monthHeader
                    weekdayRow
                    grid
                    captureRateCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Calendar")
            .navigationDestination(item: $selectedDayKey) { key in
                DayDetailView(dayKey: key)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            navButton(systemName: "chevron.left", delta: -1)
            Spacer()
            Text(Self.monthFormatter.string(from: visibleMonth))
                .font(Theme.sectionFont)
                .foregroundStyle(Theme.ink)
            Spacer()
            navButton(systemName: "chevron.right", delta: 1)
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.35 : 1)
        }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(visibleMonth, equalTo: Date(), toGranularity: .month)
    }

    private func navButton(systemName: String, delta: Int) -> some View {
        Button {
            if let next = calendar.date(byAdding: .month, value: delta, to: visibleMonth) {
                Haptics.selection(settings.hapticsEnabled)
                withAnimation(.easeInOut(duration: 0.2)) { visibleMonth = next }
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Theme.surfaceAlt, in: Circle())
                .foregroundStyle(Theme.ink)
        }
        .accessibilityLabel(delta < 0 ? "Previous month" : "Next month")
    }

    private var weekdayRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(monthGrid) { cell in
                if let date = cell.date {
                    let key = DayKey.key(for: date)
                    DayTile(
                        date: date,
                        dayMoments: byDay[key] ?? [],
                        isToday: calendar.isDateInToday(date)
                    )
                    .onTapGesture {
                        if byDay[key] != nil {
                            Haptics.tap(settings.hapticsEnabled)
                            selectedDayKey = key
                        }
                    }
                } else {
                    Color.clear.frame(height: 52)
                }
            }
        }
    }

    private var captureRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Captured this month")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(Int((captureRate * 100).rounded()))%")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(Theme.accent)
            }
            ProgressView(value: captureRate)
                .tint(Theme.accent)
        }
        .padding(16)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Captured \(Int((captureRate * 100).rounded())) percent of this month")
    }
}

/// One day cell in the month grid.
struct DayTile: View {
    let date: Date
    let dayMoments: [Moment]
    let isToday: Bool

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    private var primary: Moment? { dayMoments.first }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(primary == nil ? Theme.surfaceAlt.opacity(0.5) : Theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(isToday ? Theme.accent : Theme.hairline, lineWidth: isToday ? 2 : 1)
                )

            if let primary, primary.imageFilename?.isEmpty == false {
                MomentImageView(filename: primary.imageFilename, pointSize: 80, cornerRadius: 11)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .strokeBorder(isToday ? Theme.accent : Theme.hairline, lineWidth: isToday ? 2 : 1)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Text(dayNumber)
                            .font(Theme.rounded(11, .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 5))
                            .padding(3)
                    }
            } else {
                VStack(spacing: 4) {
                    Text(dayNumber)
                        .font(Theme.rounded(14, .semibold))
                        .foregroundStyle(primary == nil ? Theme.inkSoft : Theme.ink)
                    if let primary {
                        MoodDot(mood: primary.mood, size: 7)
                    }
                }
            }

            if dayMoments.count > 1 {
                VStack {
                    HStack {
                        Spacer()
                        Text("\(dayMoments.count)")
                            .font(Theme.rounded(9, .bold))
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background(Theme.accent, in: Circle())
                    }
                    Spacer()
                }
                .padding(3)
            }
        }
        .frame(height: 52)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if dayMoments.isEmpty {
            return "Day \(dayNumber), no moment"
        }
        let moodText = primary.map { "mood \($0.mood.label)" } ?? ""
        return "Day \(dayNumber), \(dayMoments.count) moment\(dayMoments.count == 1 ? "" : "s"), \(moodText)"
    }
}
