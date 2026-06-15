import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("suit.club.fill", "Track every session",
         "Log your cash games and tournaments in seconds — buy-in, cash-out, hours, stakes and game. Felt computes your profit instantly."),
        ("chart.line.uptrend.xyaxis", "See your real edge",
         "Hourly rate, win rate, ROI and clean breakdowns by stake, location and game — so you know exactly where you win."),
        ("shield.lefthalf.filled", "Manage your bankroll",
         "Track deposits and withdrawals, watch your roll over time, and get calm, for-your-reference guidance on cushion for your stakes."),
        ("lock.fill", "Private & offline",
         "Everything stays on your device. No account, no tracking, no network. Play responsibly — Felt is a tracking tool, not gambling advice.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                infoPage(pages[min(page, pages.count - 1)])
                    .transition(.opacity)
                    .id(page)
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
                    .shadow(color: Theme.felt.opacity(0.4), radius: 24, y: 10)
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
            PrimaryButton(title: page == pages.count - 1 ? "Get started" : "Continue",
                          systemImage: page == pages.count - 1 ? "checkmark" : "arrow.right") {
                advance()
            }
            Button("Skip") { finish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 4)
                .opacity(page == pages.count - 1 ? 0 : 1)
                .disabled(page == pages.count - 1)
            Spacer().frame(height: 12)
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
        if page < pages.count - 1 {
            let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
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
