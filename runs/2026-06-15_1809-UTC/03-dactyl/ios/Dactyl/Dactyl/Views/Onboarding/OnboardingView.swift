import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("keyboard.fill", "Type faster, the right way",
         "Dactyl drills touch-typing with a clean mechanical-keyboard feel. Follow the caret, hit the right key, and watch your WPM climb."),
        ("chart.line.uptrend.xyaxis", "See exactly where you slip",
         "Every session feeds a per-key error heatmap and your WPM trend — the signature insight that tells you which keys to practice next."),
        ("lock.shield.fill", "Private & offline",
         "Everything stays on your device. No account, no tracking, no network. Just you and the keyboard.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                infoPage(pages[safe: page] ?? pages[0])
                    .transition(.opacity)
            }
            .padding(.horizontal, 24)
        }
    }

    private func infoPage(_ p: (symbol: String, title: String, body: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 132, height: 132)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 24, y: 10)
                Image(systemName: p.symbol)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
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
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            pageDots
            PrimaryButton(title: page < pages.count - 1 ? "Continue" : "Start typing",
                          systemImage: page < pages.count - 1 ? "arrow.right" : "sparkles") {
                advance()
            }
            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 4)
            }
            Spacer().frame(height: 16)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Circle()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private func advance() {
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
        if page < pages.count - 1 {
            withAnimation(anim) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}

/// Safe collection subscript used in a few places to avoid out-of-range crashes.
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
