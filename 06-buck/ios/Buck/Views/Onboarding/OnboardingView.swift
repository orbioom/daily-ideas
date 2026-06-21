import SwiftUI

struct OnboardingView: View {
    let settings: BuckSettings
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "suit.spade.fill",
            title: "Play Euchre",
            subtitle: "The classic 4-player trick-taking card game",
            body: "Buck brings the beloved card game Euchre to your pocket. Using a 24-card deck (9 through Ace), you'll bid, call trump, and play tricks to outsmart your opponents.",
            color: Color(red: 0.55, green: 0.10, blue: 0.10)
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "You + Partner vs Two AI",
            subtitle: "Teamwork makes the difference",
            body: "You (South) partner with North against West and East. Coordinate your bids and plays — your partner's got your back. Call trump wisely and decide when to go alone for bonus points.",
            color: Color(red: 0.08, green: 0.35, blue: 0.15)
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "First to 10 Points Wins",
            subtitle: "Track your score, improve your game",
            body: "Make your contract to score 1 or 2 points. Win all 5 tricks for a march. Euchre your opponents to steal 2 points. Go alone and sweep all 5 for 4 points. First team to 10 wins!",
            color: Color(red: 0.20, green: 0.10, blue: 0.50)
        )
    ]

    var body: some View {
        ZStack {
            pages[currentPage].color
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }

                    if currentPage < pages.count - 1 {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Text("Next")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    } else {
                        Button(action: {
                            settings.hasCompletedOnboarding = true
                        }) {
                            Text("Get Started")
                                .font(.headline.bold())
                                .foregroundStyle(pages[currentPage].color)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let body: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.80))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
