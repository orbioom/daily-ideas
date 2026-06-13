import SwiftUI
import SwiftData
import Charts

struct PathView: View {
    @Query(sort: \Reflection.date, order: .reverse) private var reflections: [Reflection]

    private var stats: PracticeStats { PracticeStats.from(reflections) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if reflections.isEmpty {
                    EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                   title: "Your path begins today",
                                   message: "Complete a morning or evening reflection and your progress will appear here.")
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            statsGrid
                            moodChart
                            weeklyChart
                            calendarCard
                            recentList
                        }
                        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Path")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Reflection.self) { ReflectionDetailView(reflection: $0) }
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatTile(value: "\(stats.currentStreak)", label: "Day streak")
            StatTile(value: "\(stats.totalReflections)", label: "Reflections", accent: Theme.ink)
            StatTile(value: "\(stats.longestStreak)", label: "Longest streak")
            StatTile(value: "\(stats.morningCount)", label: "Mornings", accent: Theme.good)
            StatTile(value: "\(stats.eveningCount)", label: "Evenings", accent: Theme.ink)
            StatTile(value: stats.avgMood > 0 ? String(format: "%.1f", stats.avgMood) : "—",
                     label: "Avg mood", accent: Theme.good)
        }
    }

    @ViewBuilder private var moodChart: some View {
        if !stats.moodByDay.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Mood trend", systemImage: "waveform.path.ecg")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(stats.moodByDay) { p in
                        LineMark(x: .value("Date", p.date), y: .value("Mood", p.mood))
                            .foregroundStyle(Theme.accent)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", p.date), y: .value("Mood", p.mood))
                            .foregroundStyle(Theme.accent)
                    }
                    .frame(height: 160)
                    .chartYScale(domain: 1...5)
                    .chartYAxis { AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) }
                    .accessibilityLabel("Mood trend over the last \(stats.moodByDay.count) evening reflections, average \(String(format: "%.1f", stats.avgMood)) out of 5")
                }
            }
        }
    }

    private var weeklyData: [WeekBar] {
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for r in reflections {
            if let start = cal.dateInterval(of: .weekOfYear, for: r.date)?.start {
                buckets[start, default: 0] += 1
            }
        }
        return buckets.keys.sorted().suffix(8).map { WeekBar(weekStart: $0, count: buckets[$0] ?? 0) }
    }

    @ViewBuilder private var weeklyChart: some View {
        let data = weeklyData
        if !data.isEmpty {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Reflections per week", systemImage: "calendar")
                        .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                    Chart(data) { bar in
                        BarMark(x: .value("Week", bar.weekStart, unit: .weekOfYear),
                                y: .value("Reflections", bar.count))
                            .foregroundStyle(Theme.good)
                    }
                    .frame(height: 150)
                    .chartYAxis { AxisMarks(position: .leading) }
                    .accessibilityLabel("Reflections per week over the last \(data.count) weeks")
                }
            }
        }
    }

    private var calendarCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                MonthGrid(reflectedDays: reflectedDaySet)
            }
        }
    }

    private var reflectedDaySet: Set<Int> {
        let cal = Calendar.current
        let now = Date()
        let month = cal.component(.month, from: now)
        let year = cal.component(.year, from: now)
        var set = Set<Int>()
        for r in reflections {
            if cal.component(.month, from: r.date) == month,
               cal.component(.year, from: r.date) == year {
                set.insert(cal.component(.day, from: r.date))
            }
        }
        return set
    }

    private var recentList: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent reflections").font(Theme.rounded(15, .bold)).foregroundStyle(Theme.ink)
                let recent = Array(reflections.prefix(10))
                ForEach(Array(recent.enumerated()), id: \.offset) { idx, r in
                    NavigationLink(value: r) {
                        HStack(spacing: 12) {
                            Image(systemName: r.kind.icon)
                                .foregroundStyle(Theme.accent).frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.kind.title)
                                    .font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                Text(Fmt.relativeDay(r.date))
                                    .font(Theme.rounded(12, .regular)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            if r.kind == .evening && r.mood > 0 {
                                Text("\(r.mood)/5")
                                    .font(Theme.rounded(14, .bold)).foregroundStyle(Theme.inkSoft)
                            }
                            Image(systemName: "chevron.right").foregroundStyle(Theme.inkFaint)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    if idx < recent.count - 1 { Divider().background(Theme.hairline) }
                }
            }
        }
    }
}

private struct WeekBar: Identifiable {
    let weekStart: Date
    let count: Int
    var id: Date { weekStart }
}

/// A compact month grid marking the days a reflection was completed.
private struct MonthGrid: View {
    let reflectedDays: Set<Int>

    private let cal = Calendar.current
    private let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        let now = Date()
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let firstWeekday = leadingBlanks(for: now)
        let today = cal.component(.day, from: now)

        LazyVGrid(columns: cols, spacing: 6) {
            ForEach(weekdaySymbols(), id: \.self) { s in
                Text(s)
                    .font(Theme.rounded(10, .bold))
                    .foregroundStyle(Theme.inkFaint)
            }
            ForEach(0..<firstWeekday, id: \.self) { _ in
                Color.clear.frame(height: 30)
            }
            ForEach(1...daysInMonth, id: \.self) { day in
                let reflected = reflectedDays.contains(day)
                let isToday = day == today
                Text("\(day)")
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(reflected ? .white : Theme.inkSoft)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(reflected ? Theme.accent : Color.clear,
                                in: Circle())
                    .overlay(
                        Circle().stroke(isToday && !reflected ? Theme.accent : .clear, lineWidth: 1.5)
                    )
                    .accessibilityLabel(reflected ? "Day \(day), reflected" : "Day \(day)")
            }
        }
    }

    private func leadingBlanks(for date: Date) -> Int {
        var comps = cal.dateComponents([.year, .month], from: date)
        comps.day = 1
        guard let first = cal.date(from: comps) else { return 0 }
        let weekday = cal.component(.weekday, from: first)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private func weekdaySymbols() -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return ["S","M","T","W","T","F","S"] }
        let start = cal.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }
}
