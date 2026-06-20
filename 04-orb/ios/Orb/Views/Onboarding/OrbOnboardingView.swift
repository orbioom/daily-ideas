import SwiftUI

struct OrbOnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [(title: String, subtitle: String, icon: String, description: String)] = [
        (
            title: "Welcome to Orb",
            subtitle: "Bubble Shooter Reimagined",
            icon: "circle.hexagongrid.fill",
            description: "Fire colored bubbles to match 3 or more of the same color. Watch them pop and clear the board!"
        ),
        (
            title: "Aim & Shoot",
            subtitle: "Precision is Key",
            icon: "arrow.up.circle.fill",
            description: "Drag anywhere to aim your shot. The dotted line shows your trajectory — use wall bounces to reach tricky spots!"
        ),
        (
            title: "20 Handcrafted Levels",
            subtitle: "Master Every Challenge",
            icon: "star.circle.fill",
            description: "Each level brings new patterns and colors. Clear all bubbles to win. Disconnected bubbles fall for bonus points!"
        )
    ]

    var body: some View {
        ZStack {
            OrbTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? OrbTheme.accent : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 6, height: index == currentPage ? 10 : 6)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.bottom, 20)

                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start Playing")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(OrbTheme.accent)
                        .cornerRadius(16)
                        .padding(.horizontal, 32)
                }

                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .foregroundColor(OrbTheme.textSecondary)
                    .padding(.top, 12)
                }

                Spacer().frame(height: 40)
            }
        }
    }
}

struct OnboardingPageView: View {
    let page: (title: String, subtitle: String, icon: String, description: String)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [OrbTheme.accent, Color(red: 0.7, green: 0.3, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: OrbTheme.accent.opacity(0.5), radius: 20)

            VStack(spacing: 8) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(OrbTheme.textPrimary)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundColor(OrbTheme.accent)
            }

            Text(page.description)
                .font(.body)
                .foregroundColor(OrbTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineSpacing(4)

            Spacer()
        }
    }
}
