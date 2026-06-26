import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    @State private var page = 0

    var body: some View {
        ZStack {
            SplashTheme.background.ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingPage(
                    icon: "figure.pool.swim",
                    title: "Track Every Stroke",
                    body: "Log your swim sessions with detailed sets — stroke type, distance, reps, and rest. Private and offline.",
                    color: SplashTheme.accent
                ).tag(0)

                OnboardingPage(
                    icon: "chart.bar.xaxis",
                    title: "See Your Progress",
                    body: "Weekly distance, stroke breakdown, pace trends, and session history — all in beautiful charts.",
                    color: Color(red: 0.28, green: 0.52, blue: 0.93)
                ).tag(1)

                OnboardingPage(
                    icon: "drop.fill",
                    title: "Pools & Open Water",
                    body: "Manage your pools, set lengths, and track open-water swims separately. Your data, your device.",
                    color: Color(red: 0.20, green: 0.80, blue: 0.60)
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                Spacer()
                Button(page < 2 ? "Next" : "Get Started") {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityLabel(page < 2 ? "Next page" : "Get Started with Splash")
            }
        }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let body: String
    let color: Color

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 140, height: 140)
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }
}
