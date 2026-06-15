import SwiftUI

/// A calm completion celebration. Reduce-Motion aware: skips confetti animation
/// and shows a static, gentle congratulations card instead.
struct CelebrationOverlay: View {
    var reduceMotion: Bool
    var onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            if !reduceMotion {
                ConfettiLayer()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text("Beautiful work")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("You finished this page. It's saved to My Art.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                Button("Lovely") { onDismiss() }
                    .font(Theme.rounded(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: Theme.corner).fill(Theme.accent))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: Theme.corner + 6).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: Theme.corner + 6).strokeBorder(Theme.hairline))
            .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.85))
            .opacity(appeared ? 1 : 0)
            .padding(40)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isModal)
            .accessibilityLabel("Beautiful work. You finished this page. It's saved to My Art.")
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appeared = true }
            }
        }
    }
}

/// Lightweight falling-confetti layer (only used when Reduce Motion is off).
private struct ConfettiLayer: View {
    private let pieces: [ConfettiPiece] = (0..<40).map { _ in ConfettiPiece.random() }
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { piece in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(piece.color)
                    .frame(width: 7, height: 11)
                    .rotationEffect(.degrees(animate ? piece.endRotation : piece.startRotation))
                    .position(
                        x: piece.x * geo.size.width,
                        y: animate ? geo.size.height + 40 : -40
                    )
                    .animation(
                        .easeIn(duration: piece.duration).delay(piece.delay),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let startRotation: Double
    let endRotation: Double
    let duration: Double
    let delay: Double

    static func random() -> ConfettiPiece {
        let palette: [Color] = [Theme.accent, Color(hex: 0xF2B868), Color(hex: 0x6FBFD0),
                                Color(hex: 0xEE7FA7), Color(hex: 0x9ED06F)]
        return ConfettiPiece(
            x: CGFloat.random(in: 0...1),
            color: palette.randomElement() ?? Theme.accent,
            startRotation: Double.random(in: 0...180),
            endRotation: Double.random(in: 180...540),
            duration: Double.random(in: 1.4...2.6),
            delay: Double.random(in: 0...0.5)
        )
    }
}
