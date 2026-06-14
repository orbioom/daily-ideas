import SwiftUI

/// Generated cover art for a board game: deterministic gradient + SF Symbol + initials.
struct GameCover: View {
    let title: String
    let initials: String
    let coverHue: Int
    let symbol: String
    var cornerRadius: CGFloat = Theme.cornerMedium

    var body: some View {
        ZStack {
            Theme.coverGradient(hue: coverHue)
            // Subtle large decorative symbol.
            Image(systemName: symbol)
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(.white.opacity(0.18))
                .offset(x: 26, y: 24)
                .accessibilityHidden(true)
            VStack(spacing: 2) {
                Text(initials)
                    .font(Theme.serif(30, .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            .padding(8)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}

/// Small colored monogram chip for a player.
struct PlayerChip: View {
    let name: String
    let initials: String
    let colorHue: Int
    var size: CGFloat = 30

    var body: some View {
        Text(initials)
            .font(Theme.rounded(size * 0.42, .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.playerColor(hue: colorHue)))
            .accessibilityLabel(name)
    }
}
