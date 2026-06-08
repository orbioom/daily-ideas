import SwiftUI

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
    let symbolColor: Color
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        symbol: "leaf.fill",
        title: "Plants, kept alive — calmly.",
        body: "Verdant is a quiet companion for your indoor garden. No paywalls, no noise — just gentle reminders when your plants need you.",
        symbolColor: Brand.live
    ),
    OnboardingPage(
        symbol: "drop.fill",
        title: "Smart care, on your schedule.",
        body: "Verdant adapts to the seasons: watering a little more in summer heat, giving your plants a rest in winter.",
        symbolColor: Brand.info
    ),
    OnboardingPage(
        symbol: "chart.bar.fill",
        title: "Watch your plants thrive.",
        body: "A living care history and insights chart show you what's working — your green thumb, backed by data.",
        symbolColor: Brand.magic
    )
]

struct OnboardingView: View {
    @AppStorage("verdant.onboarded") private var onboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(onboardingPages.enumerated()), id: \.offset) { idx, p in
                        OnboardingPageView(page: p)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicator

                buttonArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<onboardingPages.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == page ? Brand.live : Brand.hairline)
                    .frame(width: idx == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? .none : Brand.ease(0.3), value: page)
                    .accessibilityHidden(true)
            }
        }
        .padding(.bottom, 32)
        .accessibilityLabel("Page \(page + 1) of \(onboardingPages.count)")
    }

    @ViewBuilder
    private var buttonArea: some View {
        VStack(spacing: 12) {
            if page < onboardingPages.count - 1 {
                Button("Next") {
                    Haptics.tap()
                    withAnimation(reduceMotion ? .none : Brand.ease()) {
                        page += 1
                    }
                }
                .buttonStyle(InkButtonStyle())
                .accessibilityHint("Go to next onboarding page")

                Button("Skip") {
                    Haptics.tap()
                    onboarded = true
                }
                .buttonStyle(GlassButtonStyle())
                .accessibilityHint("Skip introduction and open the app")
            } else {
                Button("Get Started") {
                    Haptics.success()
                    onboarded = true
                }
                .buttonStyle(InkButtonStyle())
                .accessibilityHint("Begin using Verdant")
            }
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.symbolColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.symbol)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(page.symbolColor)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }
}
