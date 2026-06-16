import SwiftUI
import SwiftData

/// Today's seeded puzzle plus the streak and a recent-days archive. Replaying past days
/// is a Pro feature.
struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var dailies: [DailyResult]

    @State private var paywallReason: PaywallReason?

    private let calendar = Calendar.current
    private let today = Date()

    private var todayPuzzle: Puzzle { PuzzleBank.dailyPuzzle(for: today, calendar: calendar) }
    private var todayKey: String { DateKey.string(for: today, calendar: calendar) }

    private var dailyByKey: [String: DailyResult] {
        Dictionary(dailies.map { ($0.dateKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var streaks: (current: Int, best: Int) {
        StatsEngine.dailyStreaks(dailies: dailies, calendar: calendar, today: today)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        streakCard
                        todayCard
                        archiveSection
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Daily")
            .navigationDestination(for: DailyDestination.self) { dest in
                PlayView(puzzle: dest.puzzle, dailyKey: dest.dateKey)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    // MARK: - Streak

    private var streakCard: some View {
        let s = streaks
        return HStack(spacing: 12) {
            StatChip(caption: "Current streak", value: "\(s.current)")
            StatChip(caption: "Best streak", value: "\(s.best)")
            StatChip(caption: "Days solved", value: "\(dailies.filter { $0.completed }.count)")
        }
    }

    // MARK: - Today

    private var todayCard: some View {
        let result = dailyByKey[todayKey]
        let done = result?.completed ?? false
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionHeader(title: "Today • \(label(today))", systemImage: "sun.max.fill")
                if done {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.good)
                        .accessibilityLabel("Completed")
                }
            }
            HStack(spacing: 14) {
                PuzzleThumbnail(puzzle: todayPuzzle, revealed: done, locked: false)
                    .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 4) {
                    Text(done ? todayPuzzle.name : "Today's puzzle")
                        .font(Theme.rounded(18, .bold)).foregroundStyle(Theme.ink)
                    Text("\(todayPuzzle.sizeLabel) • from the whole library")
                        .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    if done, let t = result?.timeSeconds, t > 0 {
                        Text("Solved in \(timeString(t))")
                            .font(Theme.mono(13, .semibold)).foregroundStyle(Theme.accentDeep)
                    }
                }
                Spacer()
            }
            NavigationLink(value: DailyDestination(puzzle: todayPuzzle, dateKey: todayKey)) {
                HStack(spacing: 8) {
                    Image(systemName: done ? "arrow.counterclockwise" : "play.fill")
                    Text(done ? "Replay today" : "Play today's puzzle").font(Theme.rounded(17, .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous).fill(Theme.heroGradient))
            }
            .buttonStyle(PressableScale())
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    // MARK: - Archive

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent days", systemImage: "calendar")
            ForEach(recentDays(), id: \.self) { day in
                archiveRow(day)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
    }

    @ViewBuilder
    private func archiveRow(_ day: Date) -> some View {
        let key = DateKey.string(for: day, calendar: calendar)
        let puzzle = PuzzleBank.dailyPuzzle(for: day, calendar: calendar)
        let result = dailyByKey[key]
        let done = result?.completed ?? false
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let canPlay = isToday || isPro

        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? Theme.good : Theme.inkFaint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(label(day)).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                Text(done ? "\(puzzle.name) • \(timeString(result?.timeSeconds ?? 0))" : "\(puzzle.sizeLabel) • unsolved")
                    .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if canPlay {
                NavigationLink(value: DailyDestination(puzzle: puzzle, dateKey: key)) {
                    Text(done ? "Replay" : "Play").font(Theme.rounded(13, .semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.accentSoft))
                }
                .buttonStyle(PressableScale())
            } else {
                Button { paywallReason = .dailyArchive } label: { ProLockChip() }
                    .buttonStyle(PressableScale())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label(day)). \(done ? "Solved \(puzzle.name)" : "Unsolved \(puzzle.sizeLabel)"). \(canPlay ? "Playable" : "Locked, requires Pro").")
    }

    // MARK: - Helpers

    private func recentDays() -> [Date] {
        var days: [Date] = []
        for i in 0..<7 {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(calendar.startOfDay(for: d))
            }
        }
        return days
    }

    private func label(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private func timeString(_ seconds: Int) -> String {
        guard seconds > 0 else { return "—" }
        let m = seconds / 60, s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

/// Navigation payload for a daily puzzle (puzzle + the date key to record under).
struct DailyDestination: Hashable {
    let puzzle: Puzzle
    let dateKey: String
}
