import SwiftUI
import SwiftData

/// The deterministic daily puzzle, with streak and a month calendar of past dailies.
struct DailyView: View {
    @Query private var results: [DailyResult]
    @State private var monthOffset = 0

    private var todayKey: String { Formatters.dayKey(.now) }
    private var todayPack: WordPack { DailyPuzzle.pack(for: todayKey) }
    private var todayPuzzle: Puzzle {
        Puzzle(packID: todayPack.id, index: 0, difficulty: DailyPuzzle.difficulty)
    }
    private var todayResult: DailyResult? {
        results.first { $0.dateKey == todayKey }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    streakCard
                    todayCard
                    calendarCard
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Daily")
        }
    }

    // MARK: Streak

    private var streakCard: some View {
        let current = StreakCalculator.current(from: results)
        let longest = StreakCalculator.longest(from: results)
        return SeekCard {
            HStack(spacing: 0) {
                streakStat(value: "\(current)", label: "Current streak", icon: "flame.fill", tint: Theme.accent)
                Divider().frame(height: 44)
                streakStat(value: "\(longest)", label: "Longest streak", icon: "trophy.fill", tint: Theme.warn)
            }
        }
    }

    private func streakStat(value: String, label: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(Theme.rounded(26, .bold)).foregroundStyle(Theme.ink)
            }
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Today

    private var todayCard: some View {
        let done = todayResult?.completed ?? false
        return SeekCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Puzzle")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Text(Formatters.mediumDate(.now))
                            .font(Theme.rounded(20, .bold))
                            .foregroundStyle(Theme.ink)
                    }
                    Spacer()
                    Image(systemName: todayPack.symbol)
                        .font(.system(size: 26))
                        .foregroundStyle(todayPack.color)
                }

                Text("Theme: \(todayPack.name) • \(DailyPuzzle.difficulty.rawValue)")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)

                if done, let r = todayResult {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        Text("Solved in \(Formatters.clock(r.timeSec))")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    NavigationLink {
                        dailyGame
                    } label: {
                        Text("Replay")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                    }
                } else {
                    NavigationLink {
                        dailyGame
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play Today's Daily")
                        }
                        .font(Theme.rounded(17, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.medium, style: .continuous)
                                .fill(Theme.heroGradient)
                        )
                    }
                }
            }
        }
    }

    private var dailyGame: some View {
        GameView(
            puzzle: todayPuzzle,
            pack: todayPack,
            isDaily: true,
            dailyDateKey: todayKey
        )
    }

    // MARK: Calendar

    private var calendarCard: some View {
        SeekCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        monthOffset -= 1
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .accessibilityLabel("Previous month")
                    Spacer()
                    Text(monthTitle)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button {
                        if monthOffset < 0 { monthOffset += 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(monthOffset >= 0)
                    .accessibilityLabel("Next month")
                }
                .foregroundStyle(Theme.accent)

                weekdayHeader
                monthGrid
            }
        }
    }

    private var weekdayHeader: some View {
        let symbols = ["S", "M", "T", "W", "T", "F", "S"]
        return HStack {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                Text(s)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var monthGrid: some View {
        let days = monthDays
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days) { day in
                dayCell(day)
            }
        }
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        Group {
            if let date = day.date {
                let key = Formatters.dayKey(date)
                let completed = results.contains { $0.dateKey == key && $0.completed }
                let isToday = key == todayKey
                ZStack {
                    Circle()
                        .fill(completed ? Theme.good.opacity(0.9) : Color.clear)
                        .frame(width: 30, height: 30)
                    if isToday && !completed {
                        Circle()
                            .strokeBorder(Theme.accent, lineWidth: 2)
                            .frame(width: 30, height: 30)
                    }
                    Text("\(day.dayNumber)")
                        .font(Theme.rounded(13, completed ? .bold : .regular))
                        .foregroundStyle(completed ? .white : Theme.ink)
                }
                .frame(height: 34)
                .accessibilityLabel("\(day.dayNumber)")
                .accessibilityValue(completed ? "Completed" : (isToday ? "Today" : "Not played"))
            } else {
                Color.clear.frame(height: 34)
            }
        }
    }

    // MARK: Month math

    private var displayedMonth: Date {
        let cal = Calendar.current
        return cal.date(byAdding: .month, value: monthOffset, to: .now) ?? .now
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: displayedMonth)
    }

    private var monthDays: [CalendarDay] {
        let cal = Calendar.current
        let month = displayedMonth
        guard let range = cal.range(of: .day, in: .month, for: month),
              let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) else {
            return []
        }
        // weekday: 1 = Sunday.
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leadingBlanks = max(0, firstWeekday - 1)

        var days: [CalendarDay] = []
        for _ in 0..<leadingBlanks {
            days.append(CalendarDay(id: "blank-\(days.count)", dayNumber: 0, date: nil))
        }
        for dayNum in range {
            let date = cal.date(byAdding: .day, value: dayNum - 1, to: firstOfMonth)
            days.append(CalendarDay(id: "day-\(dayNum)", dayNumber: dayNum, date: date))
        }
        return days
    }
}

private struct CalendarDay: Identifiable {
    let id: String
    let dayNumber: Int
    let date: Date?
}
