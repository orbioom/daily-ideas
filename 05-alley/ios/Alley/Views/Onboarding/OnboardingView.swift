import SwiftUI

struct OnboardingView: View {
    let settings: AlleySettings
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "figure.bowling",
            title: "Bowl Like a Pro",
            subtitle: "Track every game, every frame, every pin. Alley keeps the score so you can focus on your form.",
            gradient: [Color(red: 0.55, green: 0.10, blue: 0.10), Color(red: 0.30, green: 0.05, blue: 0.05)]
        ),
        OnboardingPage(
            systemImage: "checkmark.seal.fill",
            title: "Automatic Scoring",
            subtitle: "Strikes, spares, and the tricky 10th frame — all handled automatically with real bowling rules.",
            gradient: [Color(red: 0.12, green: 0.20, blue: 0.45), Color(red: 0.08, green: 0.12, blue: 0.30)]
        ),
        OnboardingPage(
            systemImage: "person.3.fill",
            title: "Up to 6 Players",
            subtitle: "Bowl with friends and family. Each player gets their own scorecard and the app tracks everyone's game.",
            gradient: [Color(red: 0.10, green: 0.30, blue: 0.15), Color(red: 0.05, green: 0.18, blue: 0.08)]
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
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                Spacer()

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 480)

                PageIndicator(count: pages.count, current: currentPage)
                    .padding(.top, 24)

                Spacer()

                VStack(spacing: 12) {
                    if currentPage < pages.count - 1 {
                        Button {
                            withAnimation { currentPage += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundStyle(AlleyTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 32)

                        Button {
                            settings.hasCompletedOnboarding = true
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    } else {
                        Button {
                            settings.hasCompletedOnboarding = true
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundStyle(AlleyTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
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
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: page.systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
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
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 16)
    }
}

struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.white : Color.white.opacity(0.35))
                    .frame(width: index == current ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}
