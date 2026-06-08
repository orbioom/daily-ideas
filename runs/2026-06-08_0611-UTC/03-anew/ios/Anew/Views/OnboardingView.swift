import SwiftUI

struct OnboardingView: View {
    @AppStorage("anew.onboarded") private var onboarded: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page: Int = 0

    var body: some View {
        ZStack {
            Brand.pageBackground

            TabView(selection: $page) {
                OnboardingPage(
                    symbol: "arrow.clockwise.heart.fill",
                    title: "Begin Again.",
                    body: "Anew is a private, unlimited sobriety tracker. Track alcohol, nicotine, sugar, screens, gambling — anything you want to quit.",
                    accentColor: Brand.live
                )
                .tag(0)

                OnboardingPage(
                    symbol: "chart.line.uptrend.xyaxis",
                    title: "All Stats. Free.",
                    body: "See your live clean streak, money saved, units avoided, health recovery milestones, and mood trends — all on device, always yours.",
                    accentColor: Brand.info
                )
                .tag(1)

                OnboardingFinalPage(onFinish: {
                    onboarded = true
                    Haptics.success()
                })
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .animation(reduceMotion ? .none : Brand.ease(), value: page)
        }
    }
}

// MARK: - Standard page

private struct OnboardingPage: View {
    let symbol: String
    let title: String
    let body: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(accentColor)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                Text(body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Final page

private struct OnboardingFinalPage: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Private by Design.")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                Text("Everything stays on your device. No account, no ads, no cloud. Just you and your commitment.")
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Spacer()

            Button("Get Started") {
                onFinish()
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.horizontal, 32)
    }
}
