import SwiftUI

/// Four-page onboarding introducing Yield. Gated by hasOnboarded. Honors Reduce Motion.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "leaf.fill",
             title: "Your dividend income, projected",
             body: "Enter your holdings — shares and dividend-per-share — and Yield projects your annual and monthly income, yield-on-cost, and more. No live prices needed."),
        Page(symbol: "calendar",
             title: "See every payday coming",
             body: "A forward 12-month payout calendar maps each holding's schedule into a clear month-by-month income forecast, with upcoming payments listed."),
        Page(symbol: "arrow.triangle.2.circlepath",
             title: "Compound it forward",
             body: "Model reinvestment (DRIP) and dividend growth over the years to see where your income could be heading. Tune it with simple sliders."),
        Page(symbol: "lock.shield.fill",
             title: "Private by design",
             body: "Everything stays on your device. No brokerage login, no account, no tracking. Yield is offline, manual, and yours.\n\nYield is for tracking and education — not financial advice.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Get started" : "Next",
                                  systemImage: page == pages.count - 1 ? "checkmark" : "arrow.right") {
                        advance()
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                        .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.rounded(29, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func advance() {
        if page < pages.count - 1 {
            Haptics.select(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
