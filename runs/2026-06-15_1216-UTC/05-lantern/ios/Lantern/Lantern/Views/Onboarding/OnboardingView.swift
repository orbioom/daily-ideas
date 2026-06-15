import SwiftUI

/// First-run onboarding, gated by `@AppStorage("hasOnboarded")`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        .init(icon: "lightbulb.max.fill",
              title: "Welcome to Lantern",
              body: "A calm, beautiful game of Mahjong solitaire. No ads, no pop-ups — just you and the board."),
        .init(icon: "hand.tap.fill",
              title: "Match free tiles",
              body: "Tap two identical tiles to clear them. A tile is free when nothing sits on top of it and at least one side is open."),
        .init(icon: "checkmark.seal.fill",
              title: "Always solvable",
              body: "Every board is built so it can be finished. Stuck? Use a hint, shuffle, or undo — and clear the board to win.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        pageView(p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                    .padding(.vertical, 12)

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: OnboardPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.accentSoft).frame(width: 130, height: 130)
                Image(systemName: p.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
            }
            Text(p.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(p.title). \(p.body)")
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var bottomButton: some View {
        Button {
            if page < pages.count - 1 {
                if reduceMotion { page += 1 } else { withAnimation { page += 1 } }
            } else {
                finish()
            }
        } label: {
            Text(page < pages.count - 1 ? "Continue" : "Start Playing")
                .font(Theme.rounded(17, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.accent)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous))
        }
        .overlay(alignment: .top) {
            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkFaint)
                    .offset(y: -36)
            }
        }
    }

    private func finish() {
        hasOnboarded = true
    }

    private struct OnboardPage {
        let icon: String
        let title: String
        let body: String
    }
}
