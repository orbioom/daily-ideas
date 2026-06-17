import SwiftUI

/// The celebratory level-complete overlay with stars, bonus count and actions.
struct WinOverlayView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let stars: Int
    let bonusCount: Int
    let isDaily: Bool
    let onNext: () -> Void
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 18) {
                Image(systemName: isDaily ? "calendar.badge.checkmark" : "checkmark.seal.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)

                Text(isDaily ? "Daily Complete!" : "Level Complete!")
                    .font(Theme.rounded(26, .heavy))
                    .foregroundStyle(Theme.ink)

                StarRatingView(stars: stars, size: 32)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.5)

                if bonusCount > 0 {
                    Label("\(bonusCount) bonus word\(bonusCount == 1 ? "" : "s") collected", systemImage: "sparkles")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }

                VStack(spacing: 10) {
                    if !isDaily {
                        PrimaryButton(title: "Continue", systemImage: "arrow.right") { onNext() }
                    }
                    SecondaryButton(title: isDaily ? "Done" : "Back to Map") { onClose() }
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
            )
            .padding(28)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
            .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appeared = true }
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
