import SwiftUI

struct WaveHUD: View {
    let game: RampartGame
    let onStartWave: () -> Void

    var body: some View {
        HStack(spacing: RampartTheme.spacingM) {
            VStack(spacing: 2) {
                Text("Wave \(game.wave + 1) / \(game.totalWaves)")
                    .font(RampartTheme.labelFont)
                    .foregroundStyle(RampartTheme.textPrimary)
                Text(game.map.name)
                    .font(RampartTheme.captionFont)
                    .foregroundStyle(RampartTheme.textSecondary)
            }

            Spacer()

            HStack(spacing: RampartTheme.spacingM) {
                Label("\(game.coins)", systemImage: "dollarsign.circle.fill")
                    .font(RampartTheme.labelFont)
                    .foregroundStyle(RampartTheme.gold)
                Label("\(game.lives)", systemImage: "heart.fill")
                    .font(RampartTheme.labelFont)
                    .foregroundStyle(RampartTheme.enemyRed)
            }

            if game.phase == .prepare {
                Button(action: onStartWave) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text("Send Wave")
                    }
                    .font(RampartTheme.labelFont)
                    .foregroundStyle(RampartTheme.background)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(RampartTheme.gold)
                    .clipShape(Capsule())
                }
            } else if game.phase == .wave {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 12))
                    Text("Defending...")
                }
                .font(RampartTheme.captionFont)
                .foregroundStyle(RampartTheme.enemyRed)
            } else if game.phase == .waveComplete {
                Text("Wave Clear! ✓")
                    .font(RampartTheme.labelFont)
                    .foregroundStyle(RampartTheme.archerGreen)
            }
        }
        .padding(.horizontal, RampartTheme.spacingM)
        .padding(.vertical, RampartTheme.spacingS)
        .background(RampartTheme.surface.opacity(0.95))
    }
}
