import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsQuery: [AppSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [VolleyOnboardingPage] = [
        VolleyOnboardingPage(
            gradient: [Color(hex: "F97316"), Color(hex: "DC2626")],
            icon: "bubble.left.and.bubble.right.fill",
            title: "Welcome to Volley",
            subtitle: "The party game for every occasion.",
            description: "Would You Rather, Truth or Dare, Never Have I Ever, and Icebreakers — all in one free app."
        ),
        VolleyOnboardingPage(
            gradient: [Color(hex: "7C3AED"), Color(hex: "4F46E5")],
            icon: "person.3.fill",
            title: "Play Together",
            subtitle: "Perfect for 2 to 20 players.",
            description: "Pick a mode, choose your vibe, and let Volley deal the questions. No setup, no subscriptions."
        ),
        VolleyOnboardingPage(
            gradient: [Color(hex: "059669"), Color(hex: "0D9488")],
            icon: "checkmark.seal.fill",
            title: "Family Friendly",
            subtitle: "Safe mode keeps it clean.",
            description: "Filter by category — Family, Friends, Couples, or Party. Every crowd covered."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(reduceMotion ? .none : .easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        VolleyOnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(reduceMotion ? .none : .spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                Button(action: handleTap) {
                    Text(currentPage == pages.count - 1 ? "Let's Play!" : "Next")
                        .font(.headline.bold())
                        .foregroundStyle(pages[currentPage].gradient.first ?? .orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
    }

    private func handleTap() {
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
            let s = AppSettings(hasCompletedOnboarding: true)
            modelContext.insert(s)
        }
    }
}

struct VolleyOnboardingPage {
    let gradient: [Color]
    let icon: String
    let title: String
    let subtitle: String
    let description: String
}

struct VolleyOnboardingPageView: View {
    let page: VolleyOnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
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
