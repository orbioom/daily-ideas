import SwiftUI

struct LevelCompleteView: View {
    let game: OrbGame
    let onNext: () -> Void
    let onReplay: () -> Void
    @State private var starsShown = 0

    private var starsEarned: Int {
        guard let level = LevelDefinition.all.first(where: { $0.number == game.currentLevel }),
              let par = level.parShots else { return 2 }
        if game.shotsUsed <= par { return 3 }
        if game.shotsUsed <= par + 5 { return 2 }
        return 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Level Complete!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [OrbTheme.accent, OrbTheme.starGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Stars display
                HStack(spacing: 12) {
                    ForEach(1...3, id: \.self) { star in
                        Image(systemName: star <= starsShown ? "star.fill" : "star")
                            .font(.system(size: 36))
                            .foregroundColor(star <= starsShown ? OrbTheme.starGold : Color.white.opacity(0.2))
                            .scaleEffect(star <= starsShown ? 1.2 : 1.0)
                            .animation(
                                .spring(duration: 0.4).delay(Double(star) * 0.2),
                                value: starsShown
                            )
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation { starsShown = starsEarned }
                    }
                }

                // Game stats
                HStack(spacing: 32) {
                    StatItem(label: "Score", value: "\(game.score)")
                    StatItem(label: "Shots", value: "\(game.shotsUsed)")
                    StatItem(label: "Popped", value: "\(game.popCount)")
                }
                .padding(.vertical, 8)

                // Action buttons
                VStack(spacing: 12) {
                    if game.currentLevel < LevelDefinition.all.count {
                        Button(action: onNext) {
                            Label("Next Level", systemImage: "arrow.right.circle.fill")
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(OrbTheme.accent)
                                .cornerRadius(14)
                        }
                    }

                    Button(action: onReplay) {
                        Label("Replay", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(OrbTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(OrbTheme.surface)
                            .cornerRadius(14)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(28)
            .background(OrbTheme.surfaceAlt)
            .cornerRadius(24)
            .padding(.horizontal, 28)
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(OrbTheme.textSecondary)
        }
    }
}
