import SwiftUI

struct GammonOnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "rectangle.checkered",
            title: "Welcome to Gammon",
            subtitle: "The classic strategy board game,\nbeautifully reimagined for iOS.",
            accent: GammonTheme.accent
        ),
        OnboardingPage(
            icon: "cpu.fill",
            title: "Play Your Way",
            subtitle: "Challenge our intelligent AI at\nEasy, Medium, or Hard difficulty.\nOr play pass-and-play with a friend.",
            accent: Color(red: 0.3, green: 0.7, blue: 0.5)
        ),
        OnboardingPage(
            icon: "trophy.fill",
            title: "Track Your Progress",
            subtitle: "Every win and loss is recorded.\nImprove your strategy and climb\nthe difficulty ladder.",
            accent: Color(red: 0.9, green: 0.5, blue: 0.2)
        ),
        OnboardingPage(
            icon: "hand.tap.fill",
            title: "Simple Controls",
            subtitle: "Tap your piece to select it.\nTap a highlighted point to move.\nRoll the dice with a tap.",
            accent: Color(red: 0.4, green: 0.5, blue: 0.9)
        )
    ]

    var body: some View {
        ZStack {
            GammonTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button("Skip") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundStyle(GammonTheme.textSecondary)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? GammonTheme.accent : GammonTheme.textMuted)
                            .frame(width: i == currentPage ? 10 : 6, height: i == currentPage ? 10 : 6)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.spring(response: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start Playing")
                        .gammonButton(large: true)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page Model

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
}

// MARK: - Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var appear = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon circle
            ZStack {
                Circle()
                    .fill(page.accent.opacity(0.15))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(page.accent.opacity(0.4), lineWidth: 2)
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(page.accent)
            }
            .scaleEffect(appear ? 1 : 0.7)
            .opacity(appear ? 1 : 0)

            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(GammonTheme.titleFont)
                    .foregroundStyle(GammonTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(GammonTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            .offset(y: appear ? 0 : 20)
            .opacity(appear ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                appear = true
            }
        }
        .onDisappear {
            appear = false
        }
    }
}

#Preview {
    GammonOnboardingView { }
}
