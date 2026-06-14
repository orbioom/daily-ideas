import SwiftUI

private struct OnboardPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
    let tint: Color
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index = 0

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "tray.full.fill",
                    title: "Capture your backlog",
                    body: "Add every game you own or want. Quest keeps your whole library private and native — no account, no feed.",
                    tint: Theme.info),
        OnboardPage(symbol: "play.circle.fill",
                    title: "Backlog → Playing → Beaten",
                    body: "Move games through a simple pipeline. Log play sessions, track hours, and watch your progress bar fill toward each game's length.",
                    tint: Theme.accent),
        OnboardPage(symbol: "dice.fill",
                    title: "What to play next?",
                    body: "Stuck choosing? Spin the picker. Filter by platform, genre or length and let Quest roll a fair pick from your backlog.",
                    tint: Theme.warning),
        OnboardPage(symbol: "trophy.fill",
                    title: "Beat your year",
                    body: "Set a yearly goal for games beaten and watch the ring fill. Stats show your pace, platforms, genres and monthly trends.",
                    tint: Theme.success)
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                        pageView(page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: index)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ page: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(page.tint.opacity(0.18))
                    .frame(width: 140, height: 140)
                Image(systemName: page.symbol)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(page.tint)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(28, .heavy))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            Spacer()
            Spacer()
        }
        .padding(.top, 40)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                advance()
            } label: {
                Text(index == pages.count - 1 ? "Start your Quest" : "Next")
                    .font(Theme.rounded(17, .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
            }
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .foregroundStyle(.white)

            Button("Skip") { finish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.textSecondary)
                .opacity(index == pages.count - 1 ? 0 : 1)
                .disabled(index == pages.count - 1)
        }
    }

    private func advance() {
        if index < pages.count - 1 {
            Haptics.play(.selection, enabled: settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { index += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.play(.success, enabled: settings.hapticsEnabled)
        hasOnboarded = true
    }
}
