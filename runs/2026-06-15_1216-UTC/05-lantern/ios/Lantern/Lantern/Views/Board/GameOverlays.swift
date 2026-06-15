import SwiftUI

/// Win / dead-end result overlay.
struct GameResultOverlay: View {
    enum Kind: Equatable {
        case won
        case deadEnd(canShuffle: Bool)
    }
    let kind: Kind
    let elapsedSec: Int
    let moves: Int
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 18) {
                Image(systemName: iconName)
                    .font(.system(size: 52))
                    .foregroundStyle(iconColor)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.6)

                Text(title)
                    .font(Theme.serif(26, .bold))
                    .foregroundStyle(Theme.ink)

                Text(subtitle)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                if case .won = kind {
                    HStack(spacing: 22) {
                        statBlock("Time", TimeFormat.clock(elapsedSec))
                        statBlock("Moves", "\(moves)")
                    }
                    .padding(.top, 4)
                }

                VStack(spacing: 10) {
                    Button(action: onPrimary) {
                        Text(primaryLabel)
                            .font(Theme.rounded(16, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                    }
                    Button(action: onSecondary) {
                        Text(secondaryLabel)
                            .font(Theme.rounded(15, .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(Theme.accent)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                    .strokeBorder(Theme.accent.opacity(0.4), lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 6)
            }
            .padding(26)
            .frame(maxWidth: 340)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.9)
            .padding(24)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { appeared = true } }
        }
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.rounded(22, .bold)).foregroundStyle(Theme.accent).monospacedDigit()
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
        }
    }

    private var iconName: String {
        switch kind {
        case .won: return "sparkles"
        case .deadEnd: return "exclamationmark.triangle.fill"
        }
    }
    private var iconColor: Color {
        switch kind {
        case .won: return Theme.gold
        case .deadEnd: return Theme.warn
        }
    }
    private var title: String {
        switch kind {
        case .won: return "Board cleared"
        case .deadEnd: return "No moves left"
        }
    }
    private var subtitle: String {
        switch kind {
        case .won: return "Beautifully done. Every tile lit and cleared."
        case .deadEnd(let canShuffle):
            return canShuffle
                ? "There are no matching free tiles. Shuffle to reopen the board, or start fresh."
                : "There are no matching free tiles, and you're out of shuffles. Start fresh, or unlock unlimited shuffles."
        }
    }
    private var primaryLabel: String {
        switch kind {
        case .won: return "Back to Menu"
        case .deadEnd(let canShuffle): return canShuffle ? "Shuffle Board" : "Unlock Shuffles"
        }
    }
    private var secondaryLabel: String {
        switch kind {
        case .won: return "Play Again"
        case .deadEnd: return "Restart Board"
        }
    }
}

/// Paused overlay.
struct PauseOverlay: View {
    let onResume: () -> Void
    let onRestart: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.gold)
                Text("Paused")
                    .font(Theme.serif(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("The timer is stopped. Take your time.")
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)

                VStack(spacing: 10) {
                    Button(action: onResume) {
                        Text("Resume")
                            .font(Theme.rounded(16, .semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 13)
                            .background(Theme.accent).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
                    }
                    Button("Restart Board", action: onRestart)
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.accent)
                    Button("Save & Exit", action: onExit)
                        .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 6)
            }
            .padding(26)
            .frame(maxWidth: 320)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 18, y: 6)
            .padding(24)
        }
    }
}
