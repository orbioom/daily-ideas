import SwiftUI

/// Multi-page onboarding. Sets `hasOnboarded` on finish.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "hexagon.fill",
             title: "Welcome to Pangram",
             body: "A warm, unlimited word game. Make as many words as you can from seven letters — free and offline, forever."),
        Page(symbol: "key.fill",
             title: "Use the center letter",
             body: "Every word must be at least four letters and must include the amber center letter. Letters can repeat."),
        Page(symbol: "star.fill",
             title: "Chase the pangram",
             body: "A word that uses all seven letters is a pangram — worth a big bonus. Climb the rank ladder to Queen Bee."),
        Page(symbol: "flame.fill",
             title: "A new puzzle every day",
             body: "Play the Daily, build a streak, and track your progress with charts. Practice puzzles whenever you like.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        pageView(p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Hexagon()
                    .fill(Theme.heroGradient)
                    .frame(width: 140, height: 140)
                Image(systemName: p.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
            Text(p.title)
                .font(Theme.rounded(28, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    hasOnboarded = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Start playing")
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(Theme.accent))
            }
            .accessibilityHint(page < pages.count - 1 ? "Goes to the next page" : "Finishes onboarding")

            if page < pages.count - 1 {
                Button("Skip") { hasOnboarded = true }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }
}
