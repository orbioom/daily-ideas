import SwiftUI

/// A lightweight, asset-free "game beaten" celebration. Respects Reduce Motion
/// (static badge instead of animated burst).
struct CelebrationOverlay: View {
    let title: String
    @Binding var isShowing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 16) {
                ZStack {
                    if !reduceMotion {
                        ForEach(0..<10, id: \.self) { i in
                            Image(systemName: "sparkle")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .offset(burstOffset(i))
                                .opacity(animate ? 0 : 1)
                                .accessibilityHidden(true)
                        }
                    }
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(Theme.warning)
                        .scaleEffect(animate || reduceMotion ? 1 : 0.4)
                }
                Text("Game Beaten!")
                    .font(Theme.rounded(24, .heavy))
                    .foregroundStyle(Theme.text)
                Text(title)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Nice!") { dismiss() }
                    .font(Theme.rounded(16, .bold))
                    .buttonStyle(.borderedProminent)
            }
            .padding(28)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .padding(40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Game beaten. \(title).")
        .onAppear {
            if reduceMotion {
                animate = true
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { animate = true }
            }
        }
    }

    private func burstOffset(_ i: Int) -> CGSize {
        let angle = Double(i) / 10.0 * 2 * .pi
        let radius: CGFloat = animate ? 80 : 0
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }

    private func dismiss() {
        if reduceMotion {
            isShowing = false
        } else {
            withAnimation(.easeOut(duration: 0.2)) { isShowing = false }
        }
    }
}
