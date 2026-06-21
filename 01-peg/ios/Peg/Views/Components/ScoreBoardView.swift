import SwiftUI

struct ScoreBoardView: View {
    let humanScore: Int
    let aiScore: Int
    let dealer: PlayerTurn

    var body: some View {
        HStack {
            scoreColumn(label: "You", score: humanScore, isDealer: dealer == .human)
            Spacer()
            VStack(spacing: 2) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(PegTheme.goldAccent)
                Text("121")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            scoreColumn(label: "AI", score: aiScore, isDealer: dealer == .ai)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(PegTheme.feltGreenDark.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func scoreColumn(label: String, score: Int, isDealer: Bool) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(PegTheme.headlineFont)
                    .foregroundStyle(.white)
                if isDealer {
                    Image(systemName: "d.circle.fill")
                        .foregroundStyle(PegTheme.goldAccent)
                        .font(.caption)
                }
            }
            Text("\(score)")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(PegTheme.goldAccent)
            ProgressView(value: Double(min(score, 121)), total: 121)
                .tint(PegTheme.goldAccent)
                .frame(width: 80)
        }
    }
}
