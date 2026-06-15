import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("circle.circle.fill", "Train with calm",
         "Tonus guides your pelvic-floor exercises with a gentle breathing ring — squeeze, hold, and relax, all on a clear rhythm. No clutter, no ads."),
        ("waveform.path.ecg", "Build the habit",
         "Follow guided programs from gentle foundations to long endurance holds. Tonus tracks your streak, minutes, and progress over time."),
        ("lock.shield.fill", "Private by design",
         "Everything stays on your device. No account, no tracking, no network. Your practice is yours alone.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if page < pages.count {
                    infoPage(pages[page]).transition(.opacity)
                } else {
                    disclaimerPage.transition(.opacity)
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
                    .font(.system(size: 54, weight: .light))
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
            Button("Skip") { goToEnd() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 4)
            Spacer().frame(height: 12)
        }
    }

    private var disclaimerPage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("A quick note")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Tonus offers general guided exercises for wellbeing. It is not medical advice and not a substitute for professional care. If you have pelvic-floor concerns, pain, or a recent surgery or birth, please consult a qualified healthcare professional before starting.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 4)
            Spacer()
            PrimaryButton(title: "I understand — let's begin", systemImage: "checkmark") { finish() }
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

    private func goToEnd() {
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
        withAnimation(anim) { page = pages.count }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
