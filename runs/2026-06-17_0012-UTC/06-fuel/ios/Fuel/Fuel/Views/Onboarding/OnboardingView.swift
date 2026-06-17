import SwiftUI

/// First-run onboarding. Three concise pages explaining the value, then a
/// "Get started" button that flips the persisted `hasOnboarded` flag. The user
/// builds their actual plan on the Plan tab afterwards (or via the seeded demo).
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @Environment(AppSettings.self) private var settings
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(icon: "flame.fill",
                    title: "Dial in your fuel",
                    body: "Fuel computes your calorie and macro targets for cutting, maintaining or a lean bulk — grounded in real metabolic math."),
        OnboardPage(icon: "wand.and.stars",
                    title: "Adapts to YOUR body",
                    body: "Log a weekly weigh-in and Fuel re-estimates your true expenditure, recommending a new target with a clear rationale. No guesswork, no subscription."),
        OnboardPage(icon: "chart.xyaxis.line",
                    title: "See the trend, not the noise",
                    body: "Smoothed weight trends, projected finish dates and a refeed schedule keep you on pace and protect your progress.")
    ]

    var body: some View {
        ZStack {
            FuelTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardPageView(page: p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    Button(page == pages.count - 1 ? "Get started" : "Next") {
                        Haptics.tap(settings.hapticsEnabled)
                        if page == pages.count - 1 {
                            hasOnboarded = true
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    .buttonStyle(FuelPrimaryButtonStyle())

                    Button("Skip") {
                        hasOnboarded = true
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

private struct OnboardPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    @Environment(\.colorScheme) private var scheme
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(FuelTheme.orange.opacity(0.14))
                    .frame(width: 140, height: 140)
                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(FuelTheme.orange)
            }
            .accessibilityHidden(true)

            Text(page.title)
                .font(.title.weight(.bold))
                .foregroundStyle(FuelTheme.primaryText(scheme))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.body)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
