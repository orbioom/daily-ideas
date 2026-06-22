import SwiftUI

struct OnboardingView: View {
    let settings: ScrawlSettings
    @State private var currentPage = 0
    @Environment(\.colorScheme) private var colorScheme

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "✏️",
            emojiBackground: Color(red: 255/255, green: 107/255, blue: 107/255),
            title: "Welcome to Scrawl!",
            subtitle: "The pass-the-phone drawing game for parties, road trips, and family nights.",
            highlights: ["Draw secret words", "Pass to your team", "Guess and earn points"]
        ),
        OnboardingPage(
            emoji: "🃏",
            emojiBackground: Color(red: 74/255, green: 144/255, blue: 217/255),
            title: "5 Word Packs",
            subtitle: "Animals, Movies & TV, Food, Sports, and Everyday Life — or build your own custom list.",
            highlights: ["200+ words built-in", "Create custom lists", "Mix any pack"]
        ),
        OnboardingPage(
            emoji: "🎉",
            emojiBackground: Color(red: 52/255, green: 199/255, blue: 89/255),
            title: "Play Anywhere",
            subtitle: "No Wi-Fi, no accounts, no subscriptions needed. Just grab a phone and play.",
            highlights: ["100% offline", "No account needed", "2–8 players or teams"]
        )
    ]

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 254/255, blue: 245/255)
                .ignoresSafeArea()
                .overlay(
                    Color(UIColor.systemBackground).opacity(colorScheme == .dark ? 1 : 0)
                        .ignoresSafeArea()
                )

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(red: 100/255, green: 100/255, blue: 102/255))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .accessibilityLabel("Skip onboarding")
                    }
                }
                .frame(height: 52)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator + button
                VStack(spacing: 24) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage
                                      ? Color(red: 74/255, green: 144/255, blue: 217/255)
                                      : Color(red: 200/255, green: 199/255, blue: 204/255))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .accessibilityLabel("Page \(currentPage + 1) of \(pages.count)")

                    // CTA Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            settings.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Let's Play!")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                currentPage < pages.count - 1
                                    ? Color(red: 74/255, green: 144/255, blue: 217/255)
                                    : Color(red: 255/255, green: 107/255, blue: 107/255)
                            )
                            .cornerRadius(16)
                            .shadow(
                                color: (currentPage < pages.count - 1
                                        ? Color(red: 74/255, green: 144/255, blue: 217/255)
                                        : Color(red: 255/255, green: 107/255, blue: 107/255)).opacity(0.35),
                                radius: 8, x: 0, y: 4
                            )
                    }
                    .padding(.horizontal, 24)
                    .accessibilityLabel(currentPage < pages.count - 1 ? "Next page" : "Get started")
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let emojiBackground: Color
    let title: String
    let subtitle: String
    let highlights: [String]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 32) {
            // Illustration
            ZStack {
                Circle()
                    .fill(page.emojiBackground.opacity(0.15))
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(page.emojiBackground.opacity(0.25))
                    .frame(width: 160, height: 160)

                Text(page.emoji)
                    .font(.system(size: 80))
            }
            .padding(.top, 24)

            // Text
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(colorScheme == .dark ? .white : Color(red: 28/255, green: 28/255, blue: 30/255))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(red: 100/255, green: 100/255, blue: 102/255))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            // Highlights
            VStack(spacing: 10) {
                ForEach(page.highlights, id: \.self) { highlight in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(page.emojiBackground)
                            .font(.system(size: 18))

                        Text(highlight)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(colorScheme == .dark ? .white : Color(red: 28/255, green: 28/255, blue: 30/255))

                        Spacer()
                    }
                    .padding(.horizontal, 40)
                }
            }

            Spacer()
        }
    }
}
