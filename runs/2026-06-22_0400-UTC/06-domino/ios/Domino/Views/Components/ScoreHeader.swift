import SwiftUI

struct ScoreHeader: View {
    let playerScore: Int
    let aiScore: Int
    let matchPointTarget: Int

    var body: some View {
        HStack {
            scoreColumn(
                label: "You",
                score: playerScore,
                target: matchPointTarget,
                isLeading: playerScore >= aiScore
            )

            Spacer()

            VStack(spacing: 2) {
                Text("MATCH")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(DominoTheme.gold.opacity(0.6))
                Text("to \(matchPointTarget)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(DominoTheme.gold)
            }

            Spacer()

            scoreColumn(
                label: "AI",
                score: aiScore,
                target: matchPointTarget,
                isLeading: aiScore > playerScore
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(DominoTheme.mahoganyDark.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(DominoTheme.gold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func scoreColumn(label: String, score: Int, target: Int, isLeading: Bool) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isLeading ? DominoTheme.gold : DominoTheme.ivory.opacity(0.6))

            Text("\(score)")
                .font(DominoTheme.scoreFont)
                .foregroundStyle(isLeading ? DominoTheme.gold : DominoTheme.ivory)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isLeading ? DominoTheme.gold : DominoTheme.ivory.opacity(0.5))
                        .frame(
                            width: geo.size.width * min(CGFloat(score) / CGFloat(target), 1.0),
                            height: 4
                        )
                        .animation(.easeInOut(duration: 0.4), value: score)
                }
            }
            .frame(width: 70, height: 4)
        }
        .frame(width: 80)
        .accessibilityLabel("\(label) score: \(score) of \(target)")
    }
}

#Preview {
    ScoreHeader(playerScore: 45, aiScore: 62, matchPointTarget: 100)
        .padding()
        .background(DominoTheme.mahogany)
}
