import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let systemImage: String
    let title: String
    let body: String
}

/// First-run onboarding. Gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(systemImage: "square.grid.3x3.fill",
                    title: "Welcome to Sapper",
                    body: "The classic Minesweeper, done right. Clean, calm, and completely free to play — no ads, ever."),
        OnboardPage(systemImage: "hand.tap.fill",
                    title: "Tap, flag, chord",
                    body: "Tap to reveal a cell. Long-press to flag a mine. Tap a number whose flags match to clear the rest."),
        OnboardPage(systemImage: "checkmark.shield.fill",
                    title: "No-guess mode",
                    body: "With Sapper Pro, every board is solvable by pure logic — no more coin-flip losses. There's a daily challenge too."),
        OnboardPage(systemImage: "chart.bar.fill",
                    title: "Honest stats",
                    body: "Track your best times, win rate and streaks across every difficulty. Your data stays on your device.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { pair in
                        pageView(pair.element)
                            .tag(pair.offset)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                pageDots
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    PrimaryButton(title: index == pages.count - 1 ? "Start playing" : "Continue",
                                  systemImage: index == pages.count - 1 ? "play.fill" : nil) {
                        advance()
                    }
                    if index < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    } else {
                        // Keep layout height stable.
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 140, height: 140)
                Image(systemName: page.systemImage)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.accent : Theme.hairline)
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: index)
            }
        }
        .accessibilityHidden(true)
    }

    private func advance() {
        if index == pages.count - 1 {
            finish()
        } else {
            withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}

#Preview {
    OnboardingView()
}
