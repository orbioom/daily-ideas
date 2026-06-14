import SwiftUI
import SwiftData

/// The daily hero. Shows today's puzzle, a Play/Resume CTA, current streak, and
/// best time. If solved, shows the solved card and a "play a random one" CTA.
struct TodayScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query private var allProgress: [PuzzleProgress]
    @Query private var allResults: [DailyResult]

    @State private var randomPuzzleID: String?

    private let today = Date()

    private var dailyPuzzle: Puzzle { PuzzleBank.daily(for: today) }
    private var todayKey: String { DateKey.key(for: today) }

    private var dailyProgress: PuzzleProgress? {
        allProgress.first { $0.puzzleID == dailyPuzzle.id }
    }

    private var todayResult: DailyResult? {
        allResults.first { $0.dateKey == todayKey }
    }

    private var isSolvedToday: Bool {
        (todayResult?.solved ?? false) || (dailyProgress?.completed ?? false)
    }

    private var currentStreak: Int {
        let keys = Set(allResults.filter { $0.solved }.map { $0.dateKey })
        return StreakService.currentStreak(solvedKeys: keys)
    }

    private var bestSeconds: Int? {
        allProgress.filter { $0.completed && $0.elapsedSeconds > 0 }
            .map { $0.elapsedSeconds }.min()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    masthead
                    statRow
                    heroCard
                    if isSolvedToday {
                        randomCard
                    }
                    tipCard
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: PuzzleRoute.self) { route in
                boardScreen(for: route)
            }
        }
    }

    // MARK: Masthead

    private var masthead: some View {
        VStack(spacing: 4) {
            Text("ACROSS")
                .font(Theme.serif(40, .bold))
                .tracking(2)
                .foregroundStyle(Theme.ink)
            Rectangle().fill(Theme.accent).frame(height: 2).frame(maxWidth: 120)
            Text(longDate)
                .font(Theme.mono(13))
                .foregroundStyle(Theme.inkSoft)
                .tracking(1)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Across, daily mini crossword, \(longDate)")
    }

    private var longDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: today).uppercased()
    }

    // MARK: Stat row

    private var statRow: some View {
        HStack(spacing: 12) {
            statTile(value: "\(currentStreak)", label: currentStreak == 1 ? "day streak" : "day streak", symbol: "flame.fill")
            statTile(value: bestSeconds.map { TimeFormat.clock($0) } ?? "—", label: "best time", symbol: "stopwatch")
            statTile(value: "\(solvedTotal)", label: "solved", symbol: "checkmark.seal.fill")
        }
    }

    private var solvedTotal: Int { allProgress.filter { $0.completed }.count }

    private func statTile(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: Hero

    private var heroCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isSolvedToday ? "TODAY'S PUZZLE — SOLVED" : "TODAY'S PUZZLE")
                        .font(Theme.mono(11, .bold))
                        .tracking(1)
                        .foregroundStyle(isSolvedToday ? Theme.good : Theme.accent)
                    Text(dailyPuzzle.title)
                        .font(Theme.serif(26, .bold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
                DifficultyTag(difficulty: dailyPuzzle.difficulty)
            }

            HStack(spacing: 16) {
                MiniGridPreview(grid: dailyPuzzle.grid, solved: isSolvedToday, side: 96)
                VStack(alignment: .leading, spacing: 8) {
                    Label("\(dailyPuzzle.size)×\(dailyPuzzle.size) \(dailyPuzzle.kindLabel)", systemImage: "square.grid.3x3")
                        .font(Theme.rounded(14, .medium))
                        .foregroundStyle(Theme.inkSoft)
                    if let p = dailyProgress, p.completed {
                        Label("Done in \(TimeFormat.clock(p.elapsedSeconds))", systemImage: "stopwatch")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.good)
                    } else if let p = dailyProgress, p.elapsedSeconds > 0 {
                        Label("In progress · \(TimeFormat.clock(p.elapsedSeconds))", systemImage: "pause.circle")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.accent)
                    } else {
                        Label("Not started", systemImage: "circle")
                            .font(Theme.rounded(14, .medium))
                            .foregroundStyle(Theme.inkFaint)
                    }
                    Spacer()
                }
                Spacer()
            }

            NavigationLink(value: PuzzleRoute(puzzleID: dailyPuzzle.id, dailyKey: todayKey)) {
                heroCTALabel
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var heroCTALabel: some View {
        HStack(spacing: 8) {
            Image(systemName: ctaIcon)
            Text(ctaTitle)
        }
        .font(Theme.rounded(17, .semibold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accent))
    }

    private var ctaTitle: String {
        if isSolvedToday { return "Review today's solve" }
        if let p = dailyProgress, p.elapsedSeconds > 0 { return "Resume puzzle" }
        return "Play today's puzzle"
    }
    private var ctaIcon: String {
        if isSolvedToday { return "checkmark.circle" }
        if let p = dailyProgress, p.elapsedSeconds > 0 { return "play.circle" }
        return "play.fill"
    }

    // MARK: Random

    private var randomCard: some View {
        VStack(spacing: 12) {
            Text("Nice solve! Keep the streak going.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
            NavigationLink(value: PuzzleRoute(puzzleID: randomID, dailyKey: nil)) {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("Play a random puzzle")
                }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.accentSoft))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
    }

    private var randomID: String {
        // Deterministic-but-varied: pick a non-daily puzzle by day + count.
        let bank = PuzzleBank.all
        guard !bank.isEmpty else { return dailyPuzzle.id }
        let seed = (DateKey.dayNumber(for: today) * 7 + solvedTotal) % bank.count
        let candidate = bank[seed]
        return candidate.id == dailyPuzzle.id ? bank[(seed + 1) % bank.count].id : candidate.id
    }

    // MARK: Tip

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Tip: tap a square once to select it, tap again to switch between Across and Down.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surfaceAlt))
    }

    // MARK: Board builder

    @ViewBuilder
    private func boardScreen(for route: PuzzleRoute) -> some View {
        if let puzzle = PuzzleBank.puzzle(id: route.puzzleID) {
            BoardScreen(puzzle: puzzle,
                        dailyDateKey: route.dailyKey,
                        progress: allProgress.first { $0.puzzleID == route.puzzleID },
                        settings: settings)
        } else {
            EmptyStateView(symbol: "questionmark.square.dashed",
                           title: "Puzzle not found",
                           message: "This puzzle is no longer available.")
        }
    }
}

/// Navigation payload for opening a board from anywhere.
struct PuzzleRoute: Hashable {
    let puzzleID: String
    /// Non-nil when this play should record toward the daily streak.
    let dailyKey: String?
}
