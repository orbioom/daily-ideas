import SwiftUI
import SwiftData

/// Today's puzzle entry plus the streak calendar and streak counters.
struct DailyView: View {
    @Query(sort: \DailyResult.date, order: .reverse) private var results: [DailyResult]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var todayKey: String { DateKey.today }
    private var puzzle: Puzzle { PuzzleGenerator.daily(for: todayKey) }
    private var todayResult: DailyResult? { results.first { $0.dateKey == todayKey } }

    private var currentStreak: Int { StreakCalculator.currentStreak(from: results) }
    private var longestStreak: Int { StreakCalculator.longestStreak(from: results) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        heroCard
                        streakRow
                        SectionCard {
                            StreakCalendarView(results: results)
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Pangram")
            .navigationDestination(for: Puzzle.self) { p in
                PlayView(puzzle: p)
            }
        }
    }

    private var heroCard: some View {
        SectionCard(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Daily")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                        Text(DateKey.display(todayKey))
                            .font(Theme.rounded(24, .heavy))
                            .foregroundStyle(Theme.ink)
                    }
                    Spacer()
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                }

                if let result = todayResult, result.wordsFound > 0 {
                    let rank = RankLadder.rank(score: result.score, max: max(puzzle.totalPossibleScore, 1))
                    HStack(spacing: 16) {
                        statPill("\(result.score)", "points")
                        statPill("\(result.wordsFound)", "words")
                        statPill(rank.title, "rank")
                    }
                }

                NavigationLink(value: puzzle) {
                    HStack {
                        Image(systemName: "play.fill").accessibilityHidden(true)
                        Text((todayResult?.wordsFound ?? 0) > 0 ? "Continue" : "Play today")
                            .font(Theme.rounded(18, .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Theme.accent))
                }
                .accessibilityHint("Opens today's puzzle")
            }
        }
    }

    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: Theme.cornerMed).fill(Theme.surfaceAlt))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var streakRow: some View {
        HStack(spacing: 14) {
            streakCard(symbol: "flame.fill", value: currentStreak, label: "Current streak")
            streakCard(symbol: "trophy.fill", value: longestStreak, label: "Longest streak")
        }
    }

    private func streakCard(symbol: String, value: Int, label: String) -> some View {
        SectionCard {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("\(value)")
                    .font(Theme.rounded(28, .heavy))
                    .foregroundStyle(Theme.ink)
                Text(label)
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) days")
    }
}
