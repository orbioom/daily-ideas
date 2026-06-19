import SwiftUI

struct OnboardingPage {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
}

struct KanaOnboardingView: View {
    @AppStorage(KanaSettings.onboardingDone) private var onboardingDone: Bool = false
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Learn Japanese Kana",
            subtitle: "Memorize all 92 hiragana and katakana characters—plus essential N5 kanji—using proven spaced repetition.",
            icon: "text.book.closed.fill",
            iconColor: KanaTheme.sakuraPink
        ),
        OnboardingPage(
            title: "Smart Flashcards",
            subtitle: "Spaced repetition shows each card at exactly the right moment, so you remember more while studying less.",
            icon: "brain.head.profile",
            iconColor: KanaTheme.goldAccent
        ),
        OnboardingPage(
            title: "Track Your Progress",
            subtitle: "See your streaks, accuracy charts, and mastery levels as you build towards fluency step by step.",
            icon: "chart.bar.fill",
            iconColor: KanaTheme.sakuraPink
        )
    ]

    var body: some View {
        ZStack {
            KanaTheme.inkBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                VStack(spacing: 24) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? KanaTheme.sakuraPink : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 7, height: index == currentPage ? 10 : 7)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Action button
                    Button(action: handleButton) {
                        Text(currentPage == pages.count - 1 ? "Let's Start!" : "Next")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(KanaTheme.crimsonRed)
                            )
                    }
                    .padding(.horizontal, 32)

                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                onboardingDone = true
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.5))
                    } else {
                        Spacer().frame(height: 20)
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func handleButton() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut) {
                currentPage += 1
            }
        } else {
            withAnimation {
                onboardingDone = true
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.15))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(page.iconColor.opacity(0.1))
                    .frame(width: 180, height: 180)
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(page.iconColor)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
