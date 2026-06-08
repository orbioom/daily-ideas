import SwiftUI

struct OnboardingView: View {
    @AppStorage("cradle.onboarded") private var onboarded = false
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "moon.stars.fill",
            color: Brand.magic,
            title: "Every moment matters.",
            body: "Cradle tracks every feed, nap, and diaper so you never lose the thread — even on two hours of sleep."
        ),
        OnboardingPage(
            symbol: "chart.bar.fill",
            color: Brand.info,
            title: "See the patterns.",
            body: "Beautiful charts reveal your baby's sleep and feed rhythms over days and weeks — all on-device, no subscription."
        ),
        OnboardingPage(
            symbol: "person.2.fill",
            color: Brand.live,
            title: "Track multiple babies.",
            body: "Switch between babies in one tap. Perfect for twins, or keeping grandma in the loop."
        )
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                // Page content
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, pg in
                        pageView(pg)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .animation(reduceMotion ? .none : Brand.ease(), value: page)

                // Indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        Capsule()
                            .fill(idx == page ? Brand.text : Brand.text3)
                            .frame(width: idx == page ? 20 : 7, height: 7)
                            .animation(reduceMotion ? .none : Brand.ease(0.3), value: page)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.bottom, 24)

                // Action buttons
                VStack(spacing: 12) {
                    if page < pages.count - 1 {
                        Button("Continue") {
                            Haptics.tap()
                            withAnimation(reduceMotion ? .none : Brand.ease()) {
                                page += 1
                            }
                        }
                        .buttonStyle(InkButtonStyle())
                        .accessibilityLabel("Continue to next page")

                        Button("Skip") {
                            Haptics.tap()
                            onboarded = true
                        }
                        .buttonStyle(GlassButtonStyle())
                        .accessibilityLabel("Skip onboarding")
                    } else {
                        Button("Get Started") {
                            Haptics.success()
                            onboarded = true
                        }
                        .buttonStyle(InkButtonStyle())
                        .accessibilityLabel("Finish onboarding and open Cradle")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func pageView(_ pg: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(pg.color.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: pg.symbol)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(pg.color)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 12) {
                Text(pg.title)
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                Text(pg.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pg.title) \(pg.body)")
    }
}

private struct OnboardingPage {
    let symbol: String
    let color: Color
    let title: String
    let body: String
}
