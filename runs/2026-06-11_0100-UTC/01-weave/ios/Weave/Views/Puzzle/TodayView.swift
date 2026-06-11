import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var attempts: [PuzzleAttempt]

    private var todayPuzzle: Puzzle { PuzzleBank.todayPuzzle() }
    private var todayAttempt: PuzzleAttempt? {
        attempts.first(where: { $0.puzzleId == todayPuzzle.id })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                NavigationLink(destination: PuzzleView(puzzleId: todayPuzzle.id)) {
                    playButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Spacer()
                difficultyGuide
                    .padding(.bottom, 40)
            }
            .navigationTitle("Weave")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Today's Puzzle")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("#\(todayPuzzle.id + 1)")
                .font(.system(size: 52, weight: .black, design: .rounded))

            if let attempt = todayAttempt {
                HStack(spacing: 6) {
                    Image(systemName: attempt.solved ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundStyle(attempt.solved ? WeaveTheme.green : .secondary)
                    Text(attempt.solved ? "Solved!" : "In progress")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(attempt.solved ? WeaveTheme.green : .secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, 24)
    }

    private var playButton: some View {
        let label = todayAttempt?.solved == true ? "Review Puzzle" :
                    todayAttempt != nil ? "Continue Puzzle" : "Play Today's Puzzle"
        return Text(label)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(WeaveTheme.purple)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel(label)
    }

    private var difficultyGuide: some View {
        VStack(spacing: 10) {
            Text("Difficulty")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 8) {
                ForEach([(1,"Easiest"),(2,"Tricky"),(3,"Hard"),(4,"Expert")], id: \.0) { d, label in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(WeaveTheme.difficultyColor(d))
                            .frame(height: 22)
                        Text(label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(label) difficulty")
                }
            }
        }
        .padding(.horizontal, 20)
    }
}
