import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        .init(symbol: "timer",
              title: "Lock in, deeply.",
              body: "Run flexible focus blocks — Pomodoro, a custom length, or open-ended flow. Pause, resume, and stay honest with a distraction counter."),
        .init(symbol: "folder.fill",
              title: "Tie focus to your work.",
              body: "Attach every session to a project and tag. Lockin remembers where your hours actually go."),
        .init(symbol: "chart.bar.xaxis",
              title: "See your focus, clearly.",
              body: "Daily and weekly minutes, time-by-project, an hour-of-day heatmap, streaks — no trees, no gimmicks.")
    ]

    var body: some View {
        ZStack {
            Theme.Palette.appBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardPageView(page: p, reduceMotion: reduceMotion)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator
                    .padding(.bottom, Theme.Spacing.lg)

                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Start focusing" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.md)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.sm)

                if page < pages.count - 1 {
                    Button("Skip", action: onFinish)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.textSecondary)
                        .padding(.bottom, Theme.Spacing.xl)
                        .accessibilityHint("Skip onboarding and start using the app")
                } else {
                    Color.clear.frame(height: 20).padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.Palette.brand : Theme.Palette.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private func advance() {
        if page < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            onFinish()
        }
    }
}

struct OnboardPage {
    let symbol: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    let reduceMotion: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.Palette.brandSoft)
                    .frame(width: 160, height: 160)
                Image(systemName: page.symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.Palette.brand)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.8)
            .opacity(appeared || reduceMotion ? 1 : 0)

            VStack(spacing: Theme.Spacing.md) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textPrimary)
                Text(page.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.Palette.textSecondary)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            Spacer()
            Spacer()
        }
        .padding()
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
