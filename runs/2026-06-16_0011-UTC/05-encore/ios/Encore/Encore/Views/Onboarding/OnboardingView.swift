import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("ticket.fill", "Every show, kept.",
         "Log the gigs you've been to — the headliner, the venue, the night. Encore turns your concert memories into a beautiful, private timeline."),
        ("music.note.list", "The setlist & the support.",
         "Remember the songs that hit, the encores, and the opening acts you discovered. It's all yours, on-device — no account, no tracking."),
        ("chart.bar.xaxis", "See your year in live music.",
         "Stats reveal your most-seen artists, top venues, and spend. Build a bucket list, count down to the next one, and share your Concert Wrapped.")
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
                    .shadow(color: Theme.accent.opacity(0.4), radius: 26, y: 10)
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
            PrimaryButton(title: page < pages.count - 1 ? "Continue" : "Start your timeline",
                          systemImage: page < pages.count - 1 ? "arrow.right" : "ticket.fill") {
                advance()
            }
            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.top, 4)
            }
            Spacer().frame(height: 18)
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

#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AppSettings())
}
