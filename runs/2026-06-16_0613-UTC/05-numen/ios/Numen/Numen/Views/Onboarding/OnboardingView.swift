import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "moon.stars.fill",
             title: "Welcome to Numen",
             body: "An elegant, private numerology companion. Discover the numbers that shape your name, your birth, and your every day."),
        Page(symbol: "circle.hexagongrid.fill",
             title: "Your full chart",
             body: "Life Path, Expression, Soul Urge, Personality, Birthday, and Maturity — each with a real interpretation and the exact math behind it."),
        Page(symbol: "heart.fill",
             title: "Cycles & compatibility",
             body: "See today's Personal Day with guidance, and compare any two people with a transparent harmony score."),
        Page(symbol: "lock.shield.fill",
             title: "Private & transparent",
             body: "Everything is computed on your device. No accounts, no tracking, no hidden method — and a one-time unlock, never a subscription.")
    ]

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            Starfield(count: 70)
                .ignoresSafeArea()
                .opacity(0.9)
            VStack {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                Button {
                    advance()
                } label: {
                    Text(page == pages.count - 1 ? "Begin" : "Continue")
                        .font(Theme.rounded(17, .semibold))
                        .foregroundStyle(Color(hex: 0x140F22))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.goldGradient, in: Capsule())
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 8)

                Button("Skip") { finish() }
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 24)
                    .accessibilityHint("Skips onboarding and opens the app")
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 70, weight: .light))
                .foregroundStyle(Theme.goldGradient)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.serif(.largeTitle))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.serif(.body))
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title). \(item.body)")
    }

    private func advance() {
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        if page < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation { hasOnboarded = true }
    }
}
