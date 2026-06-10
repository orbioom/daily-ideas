import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var context
    @Query private var games: [SavedGame]
    @Query private var allDaily: [DailyResult]
    @State private var monthAnchor = Calendar.current.startOfDay(for: .now)
    @State private var path: [SavedGame] = []

    private var calendar: Calendar { .current }
    private let dailyDifficulty: Difficulty = .medium

    private var todayKey: Int { SudokuEngine.dayKey(.now) }
    private var streak: Int { dailyStreak() }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 16) {
                        todayCard
                        calendarCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Daily")
            .navigationDestination(for: SavedGame.self) { BoardView(game: $0) }
        }
    }

    private var todayCard: some View {
        let done = allDaily.first { $0.dayKey == todayKey }?.completed ?? false
        return Button { play(.now) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Eyebrow(text: "Today's challenge")
                    Spacer()
                    if streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .font(Brand.mono(13)).foregroundStyle(Brand.warn)
                    }
                }
                HStack {
                    Image(systemName: done ? "checkmark.seal.fill" : "calendar.badge.clock")
                        .font(.largeTitle).foregroundStyle(done ? Brand.live : Brand.info)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.headline).foregroundStyle(Brand.text)
                        Text(done ? "Completed — replay anytime" : "\(dailyDifficulty.rawValue) · tap to play")
                            .font(.subheadline).foregroundStyle(Brand.text2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
                }
            }
            .glassCard()
        }
        .buttonStyle(.plain)
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
                    .disabled(isCurrentMonth).accessibilityLabel("Next month")
            }
            .foregroundStyle(Brand.text)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym).font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                ForEach(monthDays, id: \.self) { date in dayCell(date) }
            }
        }
        .glassCard()
    }

    private func dayCell(_ date: Date) -> some View {
        let inMonth = calendar.isDate(date, equalTo: monthAnchor, toGranularity: .month)
        let key = SudokuEngine.dayKey(date)
        let done = allDaily.first { $0.dayKey == key }?.completed ?? false
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: .now)
        let isToday = calendar.isDateInToday(date)
        return Button { if !isFuture { play(date) } } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(Brand.mono(13, weight: isToday ? .bold : .regular))
                .foregroundStyle(done ? .white : (inMonth && !isFuture ? Brand.text : Brand.text3.opacity(0.4)))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Circle().fill(done ? Brand.live : .clear))
                .overlay(Circle().strokeBorder(isToday ? Brand.info : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .disabled(isFuture || !inMonth)
        .opacity(inMonth ? 1 : 0.35)
        .accessibilityLabel("\(date.formatted(.dateTime.month().day()))\(done ? ", completed" : "")")
    }

    private func play(_ date: Date) {
        let game = GameService.dailyGame(for: date, difficulty: dailyDifficulty,
                                         context: context, existing: games)
        path.append(game)
    }

    private func dailyStreak() -> Int {
        let done = Set(allDaily.filter { $0.completed }.map { $0.dayKey })
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        if !done.contains(SudokuEngine.dayKey(cursor)) {
            guard let y = calendar.date(byAdding: .day, value: -1, to: cursor),
                  done.contains(SudokuEngine.dayKey(y)) else { return 0 }
            cursor = y
        }
        while done.contains(SudokuEngine.dayKey(cursor)) {
            streak += 1
            guard let p = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = p
        }
        return streak
    }

    private var monthDays: [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start) - calendar.firstWeekday
        let leading = (firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        var result: [Date] = []
        if let start = calendar.date(byAdding: .day, value: -leading, to: interval.start) {
            for i in 0..<(leading + count) {
                if let d = calendar.date(byAdding: .day, value: i, to: start) { result.append(d) }
            }
        }
        return result
    }

    private var weekdaySymbols: [String] {
        let syms = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(syms[first...] + syms[..<first])
    }

    private var isCurrentMonth: Bool { calendar.isDate(monthAnchor, equalTo: .now, toGranularity: .month) }

    private func shiftMonth(_ delta: Int) {
        if let d = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            if delta > 0 && d > Date.now { return }
            withAnimation(Brand.ease()) { monthAnchor = d }
        }
    }
}
