import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "mountain.2.fill",
             title: "Welcome to Crest",
             body: "A calm, ad-free game of TriPeaks solitaire. Clear the peaks one card at a time."),
        Page(icon: "hand.tap.fill",
             title: "Build the chain",
             body: "Tap any open card one rank above or below the waste card. Keep the chain going to grow your combo."),
        Page(icon: "rectangle.stack.fill",
             title: "Stuck? Draw a card",
             body: "Out of moves? Draw from the stock to the waste. Clear all 28 cards to win the deal."),
        Page(icon: "sparkles",
             title: "No ads. Ever.",
             body: "One quiet table, three peaks, a daily deal and your stats. Pay once for extra boards — never for the core game.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        pageView(p)
                            .tag(idx)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pager
                    .padding(.bottom, 12)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.14))
                    .frame(width: 150, height: 150)
                Image(systemName: p.icon)
                    .font(.system(size: 62, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
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
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var pager: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if page < pages.count - 1 {
                PrimaryButton(title: "Continue", icon: "arrow.right") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                PrimaryButton(title: "Start playing", icon: "play.fill") { finish() }
            }
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}
