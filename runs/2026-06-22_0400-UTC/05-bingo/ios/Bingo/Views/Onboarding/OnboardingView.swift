import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0

    let pages = [
        OnboardingPage(
            emoji: "🎱",
            title: "Welcome to Bingo!",
            subtitle: "The ultimate bingo app for parties,\nclassrooms, and family fun.",
            detail: "Play classic 75-ball number bingo or word bingo\nwith friends and family."
        ),
        OnboardingPage(
            emoji: "🎤",
            title: "Auto-Caller Built In",
            subtitle: "Let the app call the numbers\nand words for you.",
            detail: "Adjustable pace, voice announcements,\nand support for up to 4 simultaneous cards."
        ),
        OnboardingPage(
            emoji: "🏆",
            title: "Win Detection Magic",
            subtitle: "Rows, columns, diagonals,\ncorners, and blackout.",
            detail: "Tap cells to mark them. The app detects\nyour win instantly with a celebration!"
        )
    ]

    var body: some View {
        ZStack {
            BingoTheme.navy.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? BingoTheme.gold : BingoTheme.gold.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.bottom, 48)
                } else {
                    Button("Let's Play!") {
                        completeOnboarding()
                    }
                    .buttonStyle(GoldButtonStyle())
                    .padding(.bottom, 48)
                }
            }
        }
    }

    private func completeOnboarding() {
        let settings = BingoSettings()
        settings.hasCompletedOnboarding = true
        modelContext.insert(settings)
        try? modelContext.save()
    }
}

struct OnboardingPage: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let detail: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(page.emoji)
                .font(.system(size: 80))

            Text(page.title)
                .font(.largeTitle.bold())
                .foregroundColor(BingoTheme.gold)
                .multilineTextAlignment(.center)

            Text(page.subtitle)
                .font(.title3.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text(page.detail)
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}
