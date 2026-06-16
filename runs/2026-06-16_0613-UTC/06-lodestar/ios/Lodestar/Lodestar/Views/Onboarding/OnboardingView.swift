import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

/// Multi-page onboarding that explains the value and sets `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "sparkles",
                    title: "Welcome to Lodestar",
                    body: "An accurate, calm planetarium for your pocket. No account, no subscription, works fully offline."),
        OnboardPage(symbol: "circle.dotted",
                    title: "A living sky chart",
                    body: "See the stars, planets and the Moon exactly where they are right now. Pan and zoom an honest, hand-oriented map of the sky above you."),
        OnboardPage(symbol: "globe.europe.africa",
                    title: "Anywhere on Earth",
                    body: "Choose from dozens of world cities or enter your own coordinates — no location permission required."),
        OnboardPage(symbol: "moon.stars.fill",
                    title: "Tonight, at a glance",
                    body: "Which planets are up, the Moon's phase, twilight and rise-set times — plus the best objects visible right now.")
    ]

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            StarfieldBackground(reduceMotion: reduceMotion)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: p.symbol)
                                .font(.system(size: 72, weight: .thin))
                                .foregroundStyle(Theme.accent)
                                .shadow(color: Theme.accent.opacity(0.6), radius: 18)
                                .accessibilityHidden(true)
                            Text(p.title)
                                .font(Theme.rounded(28, .bold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(p.body)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(idx)
                        .accessibilityElement(children: .combine)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start exploring")
                        .font(Theme.rounded(17, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(Color(hex: 0x05070E))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 12)

                Button("Skip") { hasOnboarded = true }
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.bottom, 18)
                    .opacity(page < pages.count - 1 ? 1 : 0)
                    .accessibilityHidden(page >= pages.count - 1)
            }
        }
    }
}
