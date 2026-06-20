import SwiftUI

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        title: "Scoreboard in\nYour Pocket",
        subtitle: "Track live scores for pickup games, youth leagues, or any basketball game — right from your phone.",
        icon: "basketball.fill",
        accent: HoopTheme.orange
    ),
    OnboardingPage(
        title: "Real-Time Stats",
        subtitle: "Log every 2-pointer, 3-pointer, free throw, foul, and timeout as the action happens.",
        icon: "chart.bar.fill",
        accent: HoopTheme.teamAColor
    ),
    OnboardingPage(
        title: "Full Game History",
        subtitle: "Review box scores and quarter-by-quarter breakdowns for every game you've tracked.",
        icon: "clock.arrow.circlepath",
        accent: HoopTheme.teamBColor
    )
]

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            HoopTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentPage ? HoopTheme.orange : HoopTheme.subtleText)
                            .frame(width: i == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // CTA Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(HoopTheme.buttonFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(HoopTheme.orange)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(HoopTheme.labelFont)
                    .foregroundColor(HoopTheme.subtleText)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: page.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(page.accent)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(page.subtitle)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(HoopTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
        .preferredColorScheme(.dark)
}
