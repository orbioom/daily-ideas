import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "ear",
                    title: "Listen in on your hearing",
                    body: "Hark plays soft tones at different pitches and finds the quietest ones you can hear — a private screening you can run anytime."),
        OnboardPage(icon: "chart.xyaxis.line",
                    title: "Watch the trend, not the moment",
                    body: "One result is a snapshot. Hark keeps your history so small changes show up early — before they become big ones."),
        OnboardPage(icon: "headphones",
                    title: "Headphones + quiet = honest",
                    body: "Each ear is tested on its own, so headphones in a calm room matter. Hark is an uncalibrated screening, not a medical test."),
        OnboardPage(icon: "lock.shield",
                    title: "Yours, and only yours",
                    body: "Everything stays on your device. No accounts, no uploads. Just you and your ears.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page)
                            .tag(i)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                // Dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == index ? Theme.accent : Theme.hairline)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 8)
                .accessibilityHidden(true)

                controls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 130, height: 130)
                Image(systemName: page.icon)
                    .font(.system(size: 54, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(page.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if index < pages.count - 1 {
                PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
                }
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                PrimaryButton(title: "Start using Hark", systemImage: "checkmark") { finish() }
            }
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}
