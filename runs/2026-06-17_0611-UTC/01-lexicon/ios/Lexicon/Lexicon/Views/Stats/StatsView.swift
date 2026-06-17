import SwiftUI
import SwiftData
import Charts

/// Stats tab: lifetime totals + a guess-distribution histogram (Swift Charts).
struct StatsView: View {
    @Environment(\.colorScheme) private var scheme
    @Query private var results: [GameResult]

    private var summary: StatsSummary {
        StatsSummary.make(from: results)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LexBackground()
                if summary.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            totals
                            distributionCard
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(LexTheme.green)
                .accessibilityHidden(true)
            Text("No games yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(LexTheme.primaryText(scheme))
            Text("Play today's puzzle or a practice round and your stats will appear here.")
                .font(.subheadline)
                .foregroundStyle(LexTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
        }
    }

    // MARK: - Totals

    private var totals: some View {
        let s = summary
        return LexCard {
            VStack(spacing: 14) {
                HStack(spacing: 0) {
                    statCell("Played", "\(s.played)")
                    statCell("Win %", "\(s.winPercent)")
                    statCell("Streak", "\(s.currentStreak)")
                    statCell("Max", "\(s.maxStreak)")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Played \(s.played), win rate \(s.winPercent) percent, current streak \(s.currentStreak), max streak \(s.maxStreak)")
    }

    private func statCell(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(LexTheme.primaryText(scheme))
            Text(title)
                .font(.caption2)
                .foregroundStyle(LexTheme.secondaryText(scheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Distribution

    private var distributionCard: some View {
        let dist = summary.guessDistribution
        let maxCount = max(dist.max() ?? 0, 1)
        return LexCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Guess distribution")
                    .font(.headline)
                    .foregroundStyle(LexTheme.primaryText(scheme))

                Chart {
                    ForEach(Array(dist.enumerated()), id: \.offset) { idx, count in
                        BarMark(
                            x: .value("Guesses", "\(idx + 1)"),
                            y: .value("Wins", count)
                        )
                        .foregroundStyle(LexTheme.green)
                        .annotation(position: .top) {
                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(LexTheme.secondaryText(scheme))
                            }
                        }
                    }
                }
                .chartYScale(domain: 0...(maxCount + 1))
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
                .accessibilityLabel("Guess distribution chart")
                .accessibilityValue(distributionAccessibility(dist))

                Text("How many guesses your wins took.")
                    .font(.caption)
                    .foregroundStyle(LexTheme.secondaryText(scheme))
            }
        }
    }

    private func distributionAccessibility(_ dist: [Int]) -> String {
        dist.enumerated()
            .map { "\($0.offset + 1) guesses: \($0.element) wins" }
            .joined(separator: ", ")
    }
}
