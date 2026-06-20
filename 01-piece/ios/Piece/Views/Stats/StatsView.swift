import SwiftUI
import SwiftData

struct StatsView: View {
    @Query(sort: \PuzzleResult.completedDate, order: .reverse) private var results: [PuzzleResult]

    var body: some View {
        NavigationStack {
            ZStack {
                PieceTheme.darkBg.ignoresSafeArea()

                if results.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            summaryCards
                            bestTimesSection
                            recentSection
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundStyle(PieceTheme.amber.opacity(0.5))
            Text("No puzzles completed yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Finish your first puzzle to see stats here.")
                .font(.subheadline)
                .foregroundStyle(PieceTheme.subtleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            statCard(value: "\(results.count)", label: "Completed")
            statCard(value: bestOverallTime, label: "Best Time")
        }
        .padding(.horizontal, 20)
    }

    private var bestOverallTime: String {
        guard let best = results.map({ $0.elapsedSeconds }).min() else { return "--:--" }
        return String(format: "%d:%02d", best / 60, best % 60)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(PieceTheme.amber)
            Text(label)
                .font(.caption)
                .foregroundStyle(PieceTheme.subtleText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(PieceTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests")
                .font(.headline)
                .foregroundStyle(PieceTheme.subtleText)
                .padding(.horizontal, 20)

            VStack(spacing: 2) {
                ForEach(PuzzleArtStyle.allCases) { style in
                    ForEach(PuzzleDifficulty.allCases) { diff in
                        let best = bestTime(style: style, difficulty: diff)
                        if let t = best {
                            bestRow(style: style, difficulty: diff, seconds: t)
                        }
                    }
                }
            }
            .background(PieceTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
    }

    private func bestTime(style: PuzzleArtStyle, difficulty: PuzzleDifficulty) -> Int? {
        results
            .filter { $0.puzzleStyleId == style.rawValue && $0.difficultyId == difficulty.rawValue }
            .map { $0.elapsedSeconds }
            .min()
    }

    private func bestRow(style: PuzzleArtStyle, difficulty: PuzzleDifficulty, seconds: Int) -> some View {
        HStack {
            Circle()
                .fill(PieceTheme.difficultyColor(difficulty))
                .frame(width: 8, height: 8)
            Text(style.title)
                .font(.subheadline)
                .foregroundStyle(.white)
            Text("·")
                .foregroundStyle(PieceTheme.subtleText)
            Text(difficulty.label)
                .font(.caption)
                .foregroundStyle(PieceTheme.subtleText)
            Spacer()
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(PieceTheme.amber)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline)
                .foregroundStyle(PieceTheme.subtleText)
                .padding(.horizontal, 20)

            VStack(spacing: 2) {
                ForEach(results.prefix(20)) { result in
                    recentRow(result: result)
                }
            }
            .background(PieceTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
        }
    }

    private func recentRow(result: PuzzleResult) -> some View {
        let style = PuzzleArtStyle(rawValue: result.puzzleStyleId) ?? .mountainSunset
        let diff = PuzzleDifficulty(rawValue: result.difficultyId) ?? .beginner

        return HStack {
            PuzzleArtworkView(style: style)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 2) {
                Text(style.title)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                Text(diff.label)
                    .font(.caption)
                    .foregroundStyle(PieceTheme.subtleText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%d:%02d", result.elapsedSeconds / 60, result.elapsedSeconds % 60))
                    .font(.subheadline.monospacedDigit().bold())
                    .foregroundStyle(.white)
                Text(result.completedDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(PieceTheme.subtleText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
