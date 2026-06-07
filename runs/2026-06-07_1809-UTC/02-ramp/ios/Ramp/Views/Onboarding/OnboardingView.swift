import SwiftUI

/// A three-page paged intro to Ramp's training-load concepts. Calls `onFinish`
/// on the last page, which seeds sample data and flips the onboarding flag.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track your training load",
            message: "Every ride becomes a Training Stress Score. Ramp turns those scores into Fitness, Fatigue and Form — the picture coaches actually use."
        ),
        OnboardingPage(
            icon: "bolt.heart",
            title: "Powered by your FTP",
            message: "Log your FTP over time and Ramp computes intensity, TSS and your seven power zones automatically — in watts and watts per kilo."
        ),
        OnboardingPage(
            icon: "lock.shield",
            title: "Yours, on this device",
            message: "No account, no Strava, no cloud. Your history lives on your iPhone. We'll start you off with a sample season so the charts come alive."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i])
                        .tag(i)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            pageDots
                .padding(.top, 8)

            controls
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)
        }
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Brand.inkGradient)
                .accessibilityHidden(true)
                .padding(.bottom, 8)
            Eyebrow(text: "Ramp")
            Text(p.title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Brand.text)
                .multilineTextAlignment(.center)
            Text(p.message)
                .font(.body)
                .foregroundStyle(Brand.text2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Brand.text : Brand.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : Brand.ease(0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(page == pages.count - 1 ? "Get started" : "Continue") {
                Haptics.tap()
                if page == pages.count - 1 {
                    Haptics.success()
                    onFinish()
                } else {
                    withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                }
            }
            .buttonStyle(InkButtonStyle())

            if page < pages.count - 1 {
                Button("Skip") {
                    Haptics.tap()
                    withAnimation(reduceMotion ? nil : Brand.ease()) { page = pages.count - 1 }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.text2)
            }
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let message: String
}
