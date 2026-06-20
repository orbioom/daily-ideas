import SwiftUI
import SwiftData

struct PuzzleCompleteView: View {
    let style: PuzzleArtStyle
    let difficulty: PuzzleDifficulty
    let elapsedSeconds: Int
    let onDismiss: () -> Void

    @Query private var results: [PuzzleResult]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var bestTime: Int? {
        results
            .filter { $0.puzzleStyleId == style.rawValue && $0.difficultyId == difficulty.rawValue }
            .map { $0.elapsedSeconds }
            .min()
    }

    private var isPersonalBest: Bool {
        guard let best = bestTime else { return true }
        return elapsedSeconds <= best
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PieceTheme.darkBg.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Trophy / PB badge
                    ZStack {
                        Circle()
                            .fill(PieceTheme.amber.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: isPersonalBest ? "trophy.fill" : "checkmark.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(PieceTheme.amber)
                    }
                    .scaleEffect(reduceMotion ? 1 : 1)
                    .onAppear {
                        guard !reduceMotion else { return }
                    }

                    VStack(spacing: 8) {
                        Text(isPersonalBest ? "Personal Best!" : "Puzzle Complete!")
                            .font(.title.bold())
                            .foregroundStyle(.white)

                        Text("\(style.title) · \(difficulty.label)")
                            .font(.subheadline)
                            .foregroundStyle(PieceTheme.subtleText)
                    }

                    // Time card
                    VStack(spacing: 16) {
                        timeRow(label: "Your Time", seconds: elapsedSeconds, highlight: true)
                        if let best = bestTime, best < elapsedSeconds {
                            Divider().background(Color.white.opacity(0.1))
                            timeRow(label: "Personal Best", seconds: best, highlight: false)
                        }
                    }
                    .padding(20)
                    .background(PieceTheme.cardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)

                    Spacer()

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Play Again")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PieceTheme.amber)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        Button(action: onDismiss) {
                            Text("Back to Puzzles")
                                .font(.subheadline)
                                .foregroundStyle(PieceTheme.subtleText)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func timeRow(label: String, seconds: Int, highlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(PieceTheme.subtleText)
            Spacer()
            Text(String(format: "%d:%02d", seconds / 60, seconds % 60))
                .font(.title3.monospacedDigit().bold())
                .foregroundStyle(highlight ? PieceTheme.amber : .white)
        }
    }
}
