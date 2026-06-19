import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsQuery: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "pianokeys",
            title: "Welcome to Keys",
            subtitle: "Your personal piano teacher, right in your pocket.",
            description: "Learn to play piano from scratch — no sheet music required. Interactive lessons guide you step by step.",
            accentColor: KeysTheme.accent
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            title: "Tap to Play",
            subtitle: "Interactive piano keyboard built in.",
            description: "Touch the on-screen keys to hear real piano notes. Exercises guide your fingers and give instant feedback.",
            accentColor: Color(red: 0.220, green: 0.580, blue: 0.380)
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "Track Your Progress",
            subtitle: "Build a daily practice habit.",
            description: "See your streak, practice time, and lesson completion. Small daily sessions lead to big results.",
            accentColor: Color(red: 0.176, green: 0.478, blue: 0.310)
        )
    ]

    var body: some View {
        ZStack {
            KeysTheme.pianoBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? KeysTheme.accent : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(reduceMotion ? .none : .spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button(action: handleButtonTap) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KeysTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityLabel(currentPage == pages.count - 1 ? "Get Started" : "Next page")
            }
        }
    }

    private func handleButtonTap() {
        if currentPage < pages.count - 1 {
            withAnimation(reduceMotion ? .none : .easeInOut) {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        if let settings = settingsQuery.first {
            settings.hasCompletedOnboarding = true
        } else {
            let s = UserSettings(hasCompletedOnboarding: true)
            modelContext.insert(s)
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accentColor.opacity(0.15))
                    .frame(width: 160, height: 160)

                Image(systemName: page.icon)
                    .font(.system(size: 64))
                    .foregroundStyle(page.accentColor)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(page.accentColor)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }
}
