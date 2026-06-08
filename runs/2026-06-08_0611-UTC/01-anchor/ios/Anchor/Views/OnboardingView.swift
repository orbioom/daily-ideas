import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            symbol: "anchor",
            title: "Hold Your Days Together",
            body: "Anchor helps you build momentum with habits that actually stick. No caps, no paywalls — just your goals, tracked beautifully."
        ),
        OnboardingPage(
            symbol: "flame.fill",
            title: "Streaks That Motivate",
            body: "See your progress as streaks, heatmaps, and charts. Flexible scheduling means life happens — and your streak survives it."
        ),
        OnboardingPage(
            symbol: "lock.shield.fill",
            title: "Private by Design",
            body: "Everything stays on your device. No account, no syncing to unknown servers. Your habits are yours alone."
        )
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { idx in
                        OnboardingPageView(page: pages[idx])
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(reduceMotion ? .none : Brand.ease(), value: page)

                VStack(spacing: 12) {
                    if page == pages.count - 1 {
                        Button {
                            Haptics.success()
                            withAnimation(reduceMotion ? .none : Brand.ease()) {
                                done = true
                            }
                        } label: {
                            Text("Get Started")
                        }
                        .buttonStyle(InkButtonStyle())
                        .padding(.horizontal, 32)
                        .accessibilityHint("Begins using Anchor")
                    } else {
                        Button {
                            Haptics.selection()
                            withAnimation(reduceMotion ? .none : Brand.ease(0.3)) {
                                page = min(page + 1, pages.count - 1)
                            }
                        } label: {
                            Text("Next")
                        }
                        .buttonStyle(GlassButtonStyle())
                        .padding(.horizontal, 32)
                        .accessibilityHint("Go to next page")
                    }
                }
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Page data

private struct OnboardingPage {
    let symbol: String
    let title: String
    let body: String
}

// MARK: - Page view

private struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: page.symbol)
                .font(.system(size: 80, weight: .light))
                .foregroundStyle(Brand.inkGradient)
                .accessibilityHidden(true)
                .scaleEffect(reduceMotion ? 1 : 1)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
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
