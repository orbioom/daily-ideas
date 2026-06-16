import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("books.vertical.fill", "Your whole reading life",
         "Shelve every book — want to read, reading now, finished. Track progress page by page and watch your library grow."),
        ("flame.fill", "Make the year count",
         "Set a reading challenge and log sessions as you go. Tome tracks your pace, streaks, and projects when you'll finish."),
        ("chart.pie.fill", "See how you read",
         "Genres, pages per month, ratings, and reading pace — clear, private stats that live only on your device. No ads, no account.")
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
                    .shadow(color: Theme.accent.opacity(0.35), radius: 24, y: 10)
                Image(systemName: p.symbol)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.serif(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            pageDots
            PrimaryButton(title: page < pages.count - 1 ? "Continue" : "Start reading",
                          systemImage: page < pages.count - 1 ? "arrow.right" : "book.fill") {
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
