import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "house.fill",
            title: "Your portfolio, private",
            message: "Track every property, unit, and lease on your phone. No cloud, no account, no subscription."
        ),
        OnboardingPage(
            systemImage: "function",
            title: "Real investor math",
            message: "Cap rate, cash-on-cash, NOI, equity, and gross rent multiplier — computed for each property automatically."
        ),
        OnboardingPage(
            systemImage: "calendar.badge.clock",
            title: "Never miss rent",
            message: "A live rent roll shows who's paid, who's late, and your outstanding balance for the month."
        ),
        OnboardingPage(
            systemImage: "chart.bar.xaxis",
            title: "See the trends",
            message: "Income vs. expense, cash-flow trend, and expense breakdown charts reveal how your portfolio performs."
        )
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        OnboardingPageView(page: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots

                controls
            }
            .padding(.bottom, 28)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.accent : Theme.hairline)
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .padding(.vertical, 16)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Get started")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
                    .foregroundStyle(.white)
            }

            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .padding(.horizontal, 24)
    }

    private func finish() {
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}

struct OnboardingPage {
    let systemImage: String
    let title: String
    let message: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 168, height: 168)
                Image(systemName: page.systemImage)
                    .font(.system(size: 66, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
    }
}
