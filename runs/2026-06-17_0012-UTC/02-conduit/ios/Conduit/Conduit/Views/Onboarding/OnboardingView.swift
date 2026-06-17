import SwiftUI

/// First-run onboarding. Gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(
            symbol: "point.topleft.down.to.point.bottomright.curvepath",
            title: "Connect the dots",
            body: "Drag from one colored dot to its matching partner to lay a pipe across the board."
        ),
        OnboardPage(
            symbol: "square.grid.3x3.fill",
            title: "Fill every cell",
            body: "Pipes can't cross. Solve a level by connecting all pairs AND filling the whole grid."
        ),
        OnboardPage(
            symbol: "trophy.fill",
            title: "Build your streak",
            body: "A fresh Daily puzzle every day, plus packs from gentle 5×5 up to fiendish 9×9."
        )
    ]

    var body: some View {
        ZStack {
            ConduitTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, item in
                        OnboardPageView(page: item)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.vertical, 18)

                VStack(spacing: 12) {
                    Button(page == pages.count - 1 ? "Start playing" : "Next") {
                        if page < pages.count - 1 {
                            page += 1
                        } else {
                            hasOnboarded = true
                        }
                    }
                    .buttonStyle(ConduitPrimaryButtonStyle())

                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline)
                        .foregroundStyle(ConduitTheme.secondaryText(scheme))
                        .accessibilityLabel("Skip onboarding")
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { idx in
                Capsule()
                    .fill(idx == page ? ConduitTheme.accent : ConduitTheme.secondaryText(scheme).opacity(0.3))
                    .frame(width: idx == page ? 22 : 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardPage {
    let symbol: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    @Environment(\.colorScheme) private var scheme
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(ConduitTheme.accent.opacity(0.14))
                    .frame(width: 168, height: 168)
                Image(systemName: page.symbol)
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(ConduitTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(ConduitTheme.primaryText(scheme))
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(ConduitTheme.secondaryText(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }
}
