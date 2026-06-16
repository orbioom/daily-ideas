import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("sparkles", "Charts that are actually right",
         "Most astrology apps guess. Astra computes real planetary positions on your device with proper astronomy — accurate to the degree, every time."),
        ("circle.hexagongrid.fill", "The whole sky, drawn for you",
         "Your natal wheel, every placement, the houses, and the aspects between them — with grounded, plain-language meaning. No jargon, no fear."),
        ("moon.stars.fill", "Calm, private, and yours",
         "A daily reading rooted in real transits — never doom, never notifications begging for attention. Your chart never leaves your device.")
    ]

    var body: some View {
        ZStack {
            Theme.skyGradient.ignoresSafeArea()
            Starfield(starCount: 90)
                .ignoresSafeArea()
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
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            pageDots
            PrimaryButton(title: page < pages.count - 1 ? "Continue" : "Begin",
                          systemImage: page < pages.count - 1 ? "arrow.right" : "sparkles") {
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

#Preview {
    OnboardingView()
        .environmentObject(AppSettings())
}
