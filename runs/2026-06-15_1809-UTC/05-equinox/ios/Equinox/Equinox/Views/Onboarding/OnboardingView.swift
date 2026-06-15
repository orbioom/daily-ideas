import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("sun.horizon.fill", "A calmer way through",
         "Equinox is your private companion for perimenopause and menopause — gentle daily check-ins for hot flashes, sleep, mood, cycle changes, and the symptoms that matter to you."),
        ("chart.xyaxis.line", "See your patterns",
         "Over a few weeks, Equinox surfaces your hot-flash trends, symptom domains, cycle changes, and a clear summary you can bring to your clinician."),
        ("lock.shield.fill", "Private by design",
         "Everything stays on your device. No account, no tracking, no network. Your health is yours alone.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if page < pages.count {
                    infoPage(pages[page])
                        .transition(.opacity)
                } else {
                    consentPage
                        .transition(.opacity)
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
                    .shadow(color: Theme.accent.opacity(0.30), radius: 24, y: 10)
                Image(systemName: p.symbol)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.serif(28, .semibold))
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
            Button("Skip") { goToConsent() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 4)
            Spacer().frame(height: 12)
        }
    }

    private var consentPage: some View {
        VStack(spacing: 20) {
            Spacer()
            BotanicalSprig(size: 40)
            Text("Before we begin")
                .font(Theme.serif(26, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 14) {
                consentRow(symbol: "lock.shield.fill",
                           title: "Stays on your device",
                           body: "Your logs never leave this phone. There's no account and nothing is uploaded.")
                consentRow(symbol: "stethoscope",
                           title: "Not medical advice",
                           body: "Equinox helps you notice patterns and prepare for appointments. It does not diagnose or replace your clinician.")
                consentRow(symbol: "hand.raised.fill",
                           title: "Yours to control",
                           body: "Edit or delete any day, any time. Export a summary only when you choose to.")
            }
            .padding(18)
            .cardSurface()

            Spacer()
            PrimaryButton(title: "Start tracking", systemImage: "checkmark") { finish() }
            Spacer().frame(height: 24)
        }
    }

    private func consentRow(symbol: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
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

    private func goToConsent() {
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
        withAnimation(anim) { page = pages.count }
    }

    private func finish() {
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
