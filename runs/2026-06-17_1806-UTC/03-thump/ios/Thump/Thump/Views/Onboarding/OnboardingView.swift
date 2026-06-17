import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "square.grid.3x3.fill",
                    title: "Tap out a beat",
                    body: "Each row is a drum. Tap the steps to place hits across the 16-step grid — it's instant and there's nothing to load."),
        OnboardPage(symbol: "play.circle.fill",
                    title: "Press play",
                    body: "Hit Play and your beat loops through synthesized drum sounds. Nudge the BPM, add swing, mute tracks, and audition any pad."),
        OnboardPage(symbol: "rectangle.stack.fill",
                    title: "Save & chain",
                    body: "Save patterns to your library, swap drum kits, and chain patterns into a full song. Offline, ad-free, yours forever.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.bottom, 18)

                controls
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 140, height: 140)
                    .shadow(color: Theme.accent.opacity(0.45), radius: 24, y: 8)
                Image(systemName: page.symbol)
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(28, .heavy))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(page.title). \(page.body)"))
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Theme.accent : Theme.hairline)
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.8), value: index)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: index == pages.count - 1 ? "Start making beats" : "Next",
                          symbol: index == pages.count - 1 ? "waveform" : nil) {
                Haptics.tap(settings.hapticsEnabled)
                if index == pages.count - 1 {
                    finish()
                } else {
                    withAnimation(reduceMotion ? .none : .easeInOut) { index += 1 }
                }
            }
            if index < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func finish() {
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
