import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("userName") private var userName = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @State private var page = 0
    @State private var nameDraft = ""
    @FocusState private var nameFocused: Bool

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("circle.hexagongrid.fill", "Discover your facets",
         "Take a short, research-grounded questionnaire and see your Big Five (OCEAN) profile — plus a friendly type and archetype you can share."),
        ("lock.shield.fill", "Private & offline",
         "Everything stays on your device. No account, no tracking, no network. Your answers are yours alone."),
        ("chart.bar.doc.horizontal.fill", "Honest by design",
         "We use public-domain IPIP items and show you exactly how scoring works. The Big Five is research-based; the type label is a friendly summary, not a diagnosis.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                if page < pages.count {
                    infoPage(pages[page])
                        .transition(.opacity)
                } else {
                    namePage
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
            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                advance()
            }
            Button("Skip") { goToName() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .padding(.top, 4)
            Spacer().frame(height: 12)
        }
    }

    private var namePage: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("What should we call you?")
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("This labels your own profile. You can change it any time.")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)

            TextField("Your name", text: $nameDraft)
                .font(Theme.rounded(18, .medium))
                .multilineTextAlignment(.center)
                .focused($nameFocused)
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .cardSurface()
                .submitLabel(.done)
                .onSubmit(finish)
                .accessibilityLabel("Your name")

            Spacer()
            PrimaryButton(title: "Start exploring", systemImage: "sparkles") {
                finish()
            }
            Spacer().frame(height: 24)
        }
        .onAppear { nameFocused = true }
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

    private func goToName() {
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.25)
        withAnimation(anim) { page = pages.count }
    }

    private func finish() {
        let trimmed = nameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        userName = trimmed.isEmpty ? "You" : trimmed
        Haptics.success(enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
