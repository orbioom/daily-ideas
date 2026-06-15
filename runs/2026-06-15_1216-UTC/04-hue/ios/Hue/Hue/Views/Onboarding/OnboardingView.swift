import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "hand.tap.fill",
                    title: "Tap to fill",
                    body: "Pick a color, then tap any region of a page to fill it. Pinch to zoom, drag to pan — your work saves itself as you go."),
        OnboardPage(symbol: "number.circle.fill",
                    title: "Color by number",
                    body: "Prefer guidance? Turn on by-number mode and each region shows the color it's waiting for. Free-color whenever you like."),
        OnboardPage(symbol: "leaf.fill",
                    title: "A calm, private space",
                    body: "No ads. No feeds. No tracking. Just beautiful pages and curated palettes, all on your device.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        slide(page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                pageDots

                Button(action: advance) {
                    Text(index == pages.count - 1 ? "Start coloring" : "Next")
                        .font(Theme.rounded(18, .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                                .fill(Theme.accent)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                Button("Skip") { finish() }
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .padding(.bottom, 20)
                    .accessibilityHint("Skip the introduction and start using Hue")
            }
        }
    }

    private func slide(_ page: OnboardPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 160, height: 160)
                Image(systemName: page.symbol)
                    .font(.system(size: 70, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(30, .bold))
                    .foregroundStyle(Theme.ink)
                Text(page.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
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

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Circle()
                    .fill(i == index ? Theme.accent : Theme.hairline)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.bottom, 20)
        .accessibilityHidden(true)
    }

    private func advance() {
        if index < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}

private struct OnboardPage {
    let symbol: String
    let title: String
    let body: String
}
