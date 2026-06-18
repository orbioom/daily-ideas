import SwiftUI

/// Center-screen celebratory overlay shown when the player reaches a new rank.
struct RankToastOverlay: View {
    let rank: Rank
    let reduceMotion: Bool
    let onDismiss: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                Image(systemName: rank.isGeniusOrAbove ? "crown.fill" : "hexagon.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(rank.title)
                    .font(Theme.rounded(26, .heavy))
                    .foregroundStyle(Theme.ink)
                Text("New rank reached")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
            )
            .scaleEffect(reduceMotion ? 1 : (shown ? 1 : 0.7))
            .opacity(shown ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(shown ? 0.18 : 0).ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New rank reached: \(rank.title)")
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.7)) {
                shown = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { shown = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { onDismiss() }
            }
        }
    }
}
