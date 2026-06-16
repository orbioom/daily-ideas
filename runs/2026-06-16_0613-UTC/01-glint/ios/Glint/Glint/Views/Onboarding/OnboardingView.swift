import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
        let tint: Color
    }

    private let pages: [Page] = [
        Page(symbol: "sparkles", title: "Welcome to Glint",
             body: "A calm, fair jewel puzzle. No lives, no timers, no ads — just satisfying matches whenever you want them.",
             tint: Color(hex: 0x8B5CF6)),
        Page(symbol: "square.grid.3x3.fill", title: "Match three or more",
             body: "Swap adjacent gems to line up three or more of a kind. Each color has its own shape, so it's easy to read for everyone.",
             tint: Color(hex: 0xDB2777)),
        Page(symbol: "bolt.fill", title: "Build dazzling combos",
             body: "Match four to forge a striped gem, five to create a color bomb. Chain cascades for big multipliers.",
             tint: Color(hex: 0xF59E0B)),
        Page(symbol: "infinity", title: "Play your way",
             body: "Tackle 24 levels, unwind in endless Zen, or take on the seeded Daily challenge. Your progress is always saved.",
             tint: Color(hex: 0x2563EB))
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        pageView(p)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Start Playing" : "Next",
                                  systemImage: page == pages.count - 1 ? "play.fill" : "arrow.right") {
                        if page == pages.count - 1 {
                            finish()
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(p.tint.opacity(0.18))
                    .frame(width: 160, height: 160)
                Image(systemName: p.symbol)
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(p.tint)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private func finish() {
        hasOnboarded = true
    }
}
