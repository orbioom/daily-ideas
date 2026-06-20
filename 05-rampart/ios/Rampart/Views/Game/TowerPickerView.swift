import SwiftUI

struct TowerPickerView: View {
    let game: RampartGame
    let onSelectTower: (TowerType) -> Void

    var body: some View {
        VStack(spacing: RampartTheme.spacingS) {
            if let sel = game.selectedCell {
                let canBuild = game.canBuild(at: sel)
                if game.hasTower(at: sel) != nil {
                    Text("Tap twice to sell tower for \(game.selectedTowerType.cost / 2)g")
                        .font(RampartTheme.captionFont)
                        .foregroundStyle(RampartTheme.textSecondary)
                } else if canBuild {
                    Text("Tap again to place \(game.selectedTowerType.rawValue) (\(game.selectedTowerType.cost)g)")
                        .font(RampartTheme.captionFont)
                        .foregroundStyle(RampartTheme.textSecondary)
                }
            } else {
                Text("Tap a buildable cell • Coins: \(game.coins)g")
                    .font(RampartTheme.captionFont)
                    .foregroundStyle(RampartTheme.textTertiary)
            }

            HStack(spacing: RampartTheme.spacingS) {
                ForEach(TowerType.allCases) { type in
                    Button { onSelectTower(type) } label: {
                        VStack(spacing: 4) {
                            Text(type.emoji).font(.system(size: 26))
                            Text(type.rawValue)
                                .font(RampartTheme.captionFont)
                                .foregroundStyle(game.selectedTowerType == type ? RampartTheme.gold : RampartTheme.textSecondary)
                            Text("\(type.cost)g")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(game.coins >= type.cost ? RampartTheme.gold : .red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(game.selectedTowerType == type ? type.color.opacity(0.25) : RampartTheme.surfaceHigh)
                        .clipShape(RoundedRectangle(cornerRadius: RampartTheme.radiusM))
                        .overlay(
                            RoundedRectangle(cornerRadius: RampartTheme.radiusM)
                                .stroke(game.selectedTowerType == type ? type.color : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .opacity(game.coins >= type.cost ? 1.0 : 0.55)
                }
            }
            .padding(.horizontal, RampartTheme.spacingM)
            .padding(.bottom, RampartTheme.spacingS)
        }
        .padding(.top, RampartTheme.spacingS)
        .background(RampartTheme.surface.opacity(0.97))
    }
}
