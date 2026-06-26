import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.25, green: 0.12, blue: 0.02), Color(red: 0.15, green: 0.06, blue: 0.01)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            TabView(selection: $page) {
                OnboardPage(
                    icon: "flask.fill",
                    title: "Brew & Track Recipes",
                    body: "Build homebrew recipes with grain bills, hop schedules, and yeast. Auto-calculate ABV, IBU, and color.",
                    color: KegTheme.accent
                ).tag(0)

                OnboardPage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Log Every Batch",
                    body: "Record brew day gravities, log fermentation readings over time, and track status from grain to glass.",
                    color: Color(red: 0.2, green: 0.7, blue: 0.4)
                ).tag(1)

                OnboardPage(
                    icon: "slider.horizontal.3",
                    title: "Brewing Calculators",
                    body: "ABV from gravity, priming sugar, strike water temperature, refractometer correction — all in one place.",
                    color: Color(red: 0.3, green: 0.5, blue: 0.9)
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                Spacer()
                Button(page < 2 ? "Next" : "Start Brewing") {
                    if page < 2 { withAnimation { page += 1 } }
                    else { hasSeenOnboarding = true }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(KegTheme.accent)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct OnboardPage: View {
    let icon: String
    let title: String
    let body: String
    let color: Color

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 140, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }
}
