import SwiftUI

struct ScoreRingView: View {
    let playerScore: Int
    let opponentScore: Int
    let winningScore: Int

    var body: some View {
        HStack(spacing: 20) {
            scoreColumn(label: "You", score: playerScore, color: AnteTheme.gold)
            VStack {
                Text("First to \(winningScore)")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted)
                Text("wins")
                    .font(.caption2)
                    .foregroundColor(AnteTheme.textMuted)
            }
            scoreColumn(label: "CPU", score: opponentScore, color: .red.opacity(0.8))
        }
    }

    private func scoreColumn(label: String, score: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(AnteTheme.textSecondary)
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(score) / CGFloat(winningScore))
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: score)
                Text("\(score)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
        }
    }
}
