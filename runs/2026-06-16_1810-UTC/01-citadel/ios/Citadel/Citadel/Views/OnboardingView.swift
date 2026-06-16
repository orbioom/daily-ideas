import SwiftUI

/// First-run intro to FreeCell. Gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onStart: () -> Void

    @State private var appear = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("rectangle.stack.fill",
         "Welcome to Citadel",
         "A calm, ad-free FreeCell. Just you, the felt, and a perfectly solvable deal."),
        ("hand.tap.fill",
         "Tap to play",
         "Tap a card to pick it up, then tap where it should go. Tap a card that's ready and it flies home to its foundation."),
        ("trophy.fill",
         "Build all four suits",
         "Move every card up to the foundations — Ace to King, one suit each. Almost every deal can be won."),
    ]

    var body: some View {
        ZStack {
            theme.feltGradient(for: colorScheme).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 12)

                // Emblem
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(colorScheme == .dark ? 0.22 : 0.18))
                        .frame(width: 116, height: 116)
                    Image(systemName: "suit.spade.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(Theme.accent)
                }
                .accessibilityHidden(true)
                .scaleEffect(appear || reduceMotion ? 1 : 0.85)
                .opacity(appear || reduceMotion ? 1 : 0)

                Text("Citadel")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Theme.feltText(for: colorScheme))
                Text("FreeCell, the way it should feel")
                    .font(.headline)
                    .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))

                VStack(spacing: 18) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: page.symbol)
                                .font(.title2)
                                .foregroundStyle(Theme.gold)
                                .frame(width: 34)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(page.title)
                                    .font(.headline)
                                    .foregroundStyle(Theme.feltText(for: colorScheme))
                                Text(page.body)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.feltTextSecondary(for: colorScheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.slotFill(for: colorScheme))
                )
                .padding(.horizontal, 24)

                Spacer(minLength: 12)

                Button(action: onStart) {
                    Text("Start playing")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .accessibilityHint("Begins your first game")
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appear = true
            }
        }
    }
}
