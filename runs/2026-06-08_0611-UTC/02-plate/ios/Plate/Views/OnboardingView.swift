import SwiftUI

struct OnboardingView: View {
    var done: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Brand.pageBackground

            TabView(selection: $page) {
                OnboardingPage(
                    icon: "fork.knife",
                    headline: "Calories without the clutter.",
                    body: "Log every meal in seconds. No paywall. No ads. No syncing chaos — your data lives entirely on your device.",
                    tag: 0
                )
                OnboardingPage(
                    icon: "chart.bar.fill",
                    headline: "See your trends, not your shame.",
                    body: "A clean 14-day calorie chart, macro breakdown, and progress at a glance. You're in control.",
                    tag: 1
                )
                onboardingFinalPage
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)
        }
        .accessibilityLabel("Onboarding, page \(page + 1) of 3")
    }

    private var onboardingFinalPage: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "target")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Set your goal once.")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text("Plate computes your calorie and macro targets from your stats, or you can dial them in manually. Update anytime.")
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("Get Started") {
                Haptics.success()
                done()
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .tag(2)
    }
}

private struct OnboardingPage: View {
    let icon: String
    let headline: String
    let body: String
    let tag: Int

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(headline)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .tag(tag)
        .accessibilityElement(children: .combine)
    }
}
