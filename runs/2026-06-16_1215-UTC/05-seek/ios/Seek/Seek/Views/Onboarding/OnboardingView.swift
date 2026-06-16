import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "magnifyingglass",
            title: "Welcome to Seek",
            message: "A calm, beautiful word search. No ads, no pop-ups, ever. Just you and the grid."
        ),
        OnboardingPage(
            icon: "hand.draw.fill",
            title: "Drag to find words",
            message: "Swipe across letters in any of eight directions. Found words lock in and stay highlighted."
        ),
        OnboardingPage(
            icon: "square.grid.2x2.fill",
            title: "Themed packs & daily",
            message: "Twelve curated packs across three difficulties, plus a fresh daily puzzle and a growing streak."
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Track your progress",
            message: "Best times, solve charts, and streaks — all saved privately on your device."
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
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 12)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 9 : 7, height: i == page ? 9 : 7)
                    .animation(.snappy, value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if page < pages.count - 1 {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    withAnimation(.snappy) { page = min(page + 1, pages.count - 1) }
                }
                Button("Skip") {
                    finish()
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            } else {
                PrimaryButton(title: "Start Seeking", systemImage: "checkmark") {
                    finish()
                }
            }
        }
    }

    private func finish() {
        withAnimation { hasOnboarded = true }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let message: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.surfaceAlt)
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 58, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
