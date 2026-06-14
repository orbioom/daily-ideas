import SwiftUI

/// First-run onboarding. Three calm pages, gated by `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("defaultLayout") private var defaultLayout = LayoutStyle.tree.rawValue
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [Page] = [
        Page(symbol: "circle.hexagongrid.fill",
             title: "Think in branches",
             body: "Aster turns a single idea into a calm, radiating map. Capture a thought, then grow it outward."),
        Page(symbol: "list.bullet.indent",
             title: "Map or outline",
             body: "See the same thoughts as a beautiful canvas or a tidy indented outline. They always stay in sync."),
        Page(symbol: "lock.open",
             title: "Yours, one time",
             body: "No subscriptions. The free tier is genuinely useful, and Aster Pro is a single, honest unlock.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i])
                            .tag(i)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.bottom, 8)

                controls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 150, height: 150)
                Image(systemName: p.symbol)
                    .font(.system(size: 62, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(p.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start mapping")
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func finish() {
        // Seed a sensible default layout preference if unset.
        if LayoutStyle(rawValue: defaultLayout) == nil {
            defaultLayout = LayoutStyle.tree.rawValue
        }
        Haptics.success()
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }

    private struct Page {
        let symbol: String
        let title: String
        let body: String
    }
}
