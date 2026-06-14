import SwiftUI

/// First-run onboarding. Three calm pages, then sets `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [Page] = [
        Page(symbol: "hourglass",
             title: "Every day counts",
             body: "Cusp keeps your most-anticipated days — and your fondest memories — one glance away."),
        Page(symbol: "rectangle.stack.fill",
             title: "Beautiful by default",
             body: "Gradient cards with live tickers make counting down feel like a small daily ritual."),
        Page(symbol: "lock.open.fill",
             title: "Honest from day one",
             body: "Free to track up to five events with full counting. No ads, no paywalled widgets, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                indicators

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 150, height: 150)
                Image(systemName: p.symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(p.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(p.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
    }

    private var indicators: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .padding(.bottom, 20)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap(enabled: settings.hapticsEnabled)
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start counting")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Button {
                finish()
            } label: {
                Text("Skip")
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .opacity(page < pages.count - 1 ? 1 : 0)
            .disabled(page == pages.count - 1)
        }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation { hasOnboarded = true }
    }

    private struct Page {
        let symbol: String
        let title: String
        let body: String
    }
}
