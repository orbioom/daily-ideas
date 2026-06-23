import SwiftUI

/// Three-page first-run onboarding. Finishing sets the persisted `didOnboard` flag.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "wind", tint: Theme.calmTeal,
                    title: "Breathe with Ember",
                    body: "A calm coach for your breath. Follow a gentle pacer through proven techniques — anytime, fully offline."),
        OnboardPage(icon: "square.grid.2x2", tint: Theme.deepBlue,
                    title: "Five techniques, your way",
                    body: "Box breathing to focus, 4-7-8 to unwind, coherent breathing to balance, quick energizers, and Wim-Hof-style power rounds."),
        OnboardPage(icon: "chart.bar.xaxis", tint: Theme.emberWarm,
                    title: "See yourself settle",
                    body: "Check in on your mood before and after, build a daily streak, and watch your calm grow in simple charts."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardPageView(page: item, reduceMotion: reduceMotion)
                        .tag(index)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: Theme.Spacing.md) {
                Button(action: advance) {
                    Text(page == pages.count - 1 ? "Start Breathing" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint(page == pages.count - 1 ? "Finishes setup and opens the app" : "Goes to the next page")

                if page < pages.count - 1 {
                    Button("Skip") { onFinish() }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .emberScreenBackground()
    }

    private func advance() {
        Haptics.shared.tap()
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            onFinish()
        }
    }
}

private struct OnboardPage {
    let icon: String
    let tint: Color
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    let reduceMotion: Bool
    @State private var pulse = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.18))
                    .frame(width: 200, height: 200)
                    .scaleEffect(reduceMotion ? 1 : (pulse ? 1.06 : 0.94))
                Image(systemName: page.icon)
                    .font(.system(size: 78, weight: .light))
                    .foregroundStyle(page.tint)
                    .accessibilityHidden(true)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }

            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textPrimary)

            Text(page.body)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
