import SwiftUI

struct OnboardingView: View {
    let settings: CountSettings
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "suit.spade.fill",
            title: "Master Blackjack Strategy",
            subtitle: "Learn the mathematically optimal play for every hand. Count trains you with real casino basic strategy.",
            actionTitle: nil
        ),
        OnboardingPage(
            systemImage: "checkmark.seal.fill",
            title: "Instant Feedback",
            subtitle: "See if your choice was correct immediately. Learn from every mistake and build muscle memory for optimal play.",
            actionTitle: nil
        ),
        OnboardingPage(
            systemImage: "chart.bar.fill",
            title: "Track Your Progress",
            subtitle: "Detailed stats show where you need more practice. Identify your weakest scenarios and drill them to perfection.",
            actionTitle: "Get Started"
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [CountTheme.gradientStart, CountTheme.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 8)

                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                settings.hasCompletedOnboarding = true
                            }
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(CountTheme.tableGreen)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage {
    let systemImage: String
    let title: String
    let subtitle: String
    let actionTitle: String?
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: page.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .foregroundStyle(.white)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 12)
            }
            .padding(.horizontal, 16)

            Spacer()
            Spacer()
        }
    }
}
