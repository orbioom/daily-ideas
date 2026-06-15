import SwiftUI

/// Result reveal animation shown after computing. Tapping continue saves & opens detail.
struct RevealView: View {
    let result: ScoredResult
    let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var archetype: Archetype { result.archetype }
    private var identity: Identity { TypeMapper.identity(for: result.traitScores) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("You are")
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.inkSoft)
                    .opacity(appeared ? 1 : 0)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Theme.heroGradient)
                    VStack(spacing: 14) {
                        TypeBadge(code: result.typeCode, identity: identity, size: 44)
                        Text(archetype.name)
                            .font(Theme.rounded(30, .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        Text(archetype.tagline)
                            .font(Theme.rounded(15))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(24)
                }
                .frame(maxWidth: .infinity)
                .scaleEffect(appeared ? 1 : (reduceMotion ? 1 : 0.85))
                .opacity(appeared ? 1 : 0)
                .shadow(color: Theme.accent.opacity(0.3), radius: 18, y: 8)

                VStack(spacing: 12) {
                    ForEach(result.traitScores) { ts in
                        TraitBar(traitScore: ts, showPercentage: true, animate: appeared)
                    }
                }
                .padding(18)
                .cardSurface()
                .opacity(appeared ? 1 : 0)

                PrimaryButton(title: "See full result", systemImage: "arrow.right") {
                    onContinue()
                }
                .opacity(appeared ? 1 : 0)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
        }
        .accessibilityAction(.magicTap) { onContinue() }
    }
}
