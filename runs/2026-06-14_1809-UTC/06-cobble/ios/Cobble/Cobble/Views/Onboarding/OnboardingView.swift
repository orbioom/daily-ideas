import SwiftUI

/// Three-page onboarding explaining how Cobble plays. Gated by hasOnboarded.
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
        Page(symbol: "square.grid.3x3.fill",
             title: "Drop blocks, fill the grid",
             body: "Tap a piece to pick it up, then tap the board to drop it. Place all kinds of shapes onto the calm 8×8 grid — no timer, ever."),
        Page(symbol: "rectangle.split.3x3.fill",
             title: "Clear lines to score",
             body: "Fill a full row or column and it clears in a satisfying flash. Clear several at once — or on back-to-back turns — to build combos and big scores."),
        Page(symbol: "infinity",
             title: "Play your way",
             body: "An endless Classic that resumes right where you left off, plus a fresh Daily challenge everyone shares. Ad-free, calm, and yours.")
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
                    PrimaryButton(title: page == pages.count - 1 ? "Start playing" : "Next",
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
                .font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.rounded(30, .bold))
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
        Haptics.clear(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
