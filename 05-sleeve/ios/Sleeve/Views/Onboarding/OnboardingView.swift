import SwiftUI

private struct OnboardingPage {
    let title: String
    let subtitle: String
    let systemImage: String
    let imageColor: Color
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        title: "Your Collection,\nOrganized",
        subtitle: "Catalog every card — Pokemon, Magic, Sports, and more. Track condition, rarity, and estimated value in one place.",
        systemImage: "rectangle.on.rectangle.angled",
        imageColor: SleeveTheme.accent
    ),
    OnboardingPage(
        title: "Build Your Decks",
        subtitle: "Assemble and manage decks across all your favorite games and formats. Keep a living record of every build.",
        systemImage: "rectangle.stack.fill",
        imageColor: SleeveTheme.gold
    ),
    OnboardingPage(
        title: "Track What You Want",
        subtitle: "Never forget a card you're hunting for. Set priority and max price targets on your want list.",
        systemImage: "heart.fill",
        imageColor: Color(red: 0.95, green: 0.35, blue: 0.55)
    ),
]

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            SleeveTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? SleeveTheme.accent : SleeveTheme.silver.opacity(0.4))
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SleeveTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.imageColor.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: page.systemImage)
                    .font(.system(size: 72))
                    .foregroundStyle(page.imageColor)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(SleeveTheme.silver)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
}
