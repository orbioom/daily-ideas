import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("eye.fill", "Rest your eyes, often",
         "Iris follows the 20-20-20 rule: every 20 minutes, look ~20 feet away for 20 seconds. A calm focus target guides each break."),
        ("figure.mind.and.body", "Gentle guided exercises",
         "Follow a soft moving dot through relax, strengthen, focus and dry-eye routines — built to ease the strain of long screen days."),
        ("chart.line.uptrend.xyaxis", "See your progress",
         "Track breaks, streaks and exercise minutes. Quiet charts show how your eye-care habit grows — no ads, no account, all on-device.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if page < pages.count {
                    infoPage(pages[page]).transition(.opacity)
                } else {
                    finishPage.transition(.opacity)
                }
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
            PrimaryButton(title: "Continue", systemImage: "arrow.right") { advance() }
            Button("Skip") { goToFinish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 4)
            Spacer().frame(height: 12)
        }
    }

    private var finishPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("A calmer screen day")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Take your first 20-20-20 break whenever your eyes need it. Iris keeps everything quiet and private.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Iris supports healthy screen habits. It is not a medical eye exam — see an optometrist for vision concerns.")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.top, 4)

            Spacer()
            PrimaryButton(title: "Get started", systemImage: "sparkles") { finish() }
            Spacer().frame(height: 24)
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
        withAnimation(anim) {
            if page < pages.count - 1 { page += 1 } else { page = pages.count }
        }
    }

    private func goToFinish() {
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
        withAnimation(anim) { page = pages.count }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
