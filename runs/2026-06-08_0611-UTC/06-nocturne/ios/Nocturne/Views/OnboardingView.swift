import SwiftUI

struct OnboardingView: View {
    @AppStorage("nocturne.onboarded") private var onboarded = false
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            iconColor: Brand.magic,
            title: "Understand\nyour nights.",
            body: "Nocturne tracks your sleep manually — no wearable, no subscription. Just honest insight into how well you actually rest."
        ),
        OnboardingPage(
            icon: "chart.bar.xaxis",
            iconColor: Brand.info,
            title: "Sleep debt &\nconsistency.",
            body: "See your 14-night rolling sleep debt and a regularity score based on how consistent your bedtimes and wake times are."
        ),
        OnboardingPage(
            icon: "target",
            iconColor: Brand.live,
            title: "Set a goal,\ntrack the trend.",
            body: "Pick your target sleep hours and ideal wake time. Nocturne shows your recommended bedtime every night."
        ),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .animation(reduceMotion ? nil : Brand.ease(), value: page)

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { idx in
                        Capsule()
                            .fill(idx == page ? Brand.magic : Brand.hairline)
                            .frame(width: idx == page ? 20 : 8, height: 8)
                            .animation(reduceMotion ? nil : Brand.ease(0.3), value: page)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.bottom, 24)

                // Action button
                VStack(spacing: 12) {
                    if page < pages.count - 1 {
                        Button("Continue") {
                            Haptics.tap()
                            withAnimation(reduceMotion ? nil : Brand.ease()) {
                                page += 1
                            }
                        }
                        .buttonStyle(InkButtonStyle())
                        .accessibilityHint("Go to next page")
                    } else {
                        Button("Get Started") {
                            Haptics.success()
                            withAnimation(reduceMotion ? nil : Brand.ease()) {
                                onboarded = true
                            }
                        }
                        .buttonStyle(InkButtonStyle())
                        .accessibilityHint("Finish onboarding and open the app")
                    }

                    if page > 0 {
                        Button("Back") {
                            Haptics.tap()
                            withAnimation(reduceMotion ? nil : Brand.ease()) {
                                page -= 1
                            }
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let body: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.iconColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(page.iconColor)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
