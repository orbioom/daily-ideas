import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(
            symbol: "square.stack.3d.up.fill",
            title: "Boards, not lists",
            message: "Lane is a visual board. Drag your work across columns — Backlog to Done — and see the whole picture at a glance."
        ),
        OnboardPage(
            symbol: "rectangle.split.3x1",
            title: "Built for flow",
            message: "Add cards with due dates, priorities, labels and checklists. Move them between lanes with a tap — no fiddly drag required."
        ),
        OnboardPage(
            symbol: "lock.shield.fill",
            title: "Private & native",
            message: "Everything lives on your iPhone. No account, no cloud, no subscription. Fast, offline, and yours."
        ),
        OnboardPage(
            symbol: "chart.bar.xaxis",
            title: "See your momentum",
            message: "Agenda keeps every due date in one place, and Insights shows what you're shipping each week."
        )
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardPageView(page: p)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    Button {
                        advance()
                    } label: {
                        Text(page == pages.count - 1 ? "Start using Lane" : "Continue")
                            .font(Theme.rounded(17, .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .accessibilityHint(page == pages.count - 1 ? "Finishes onboarding" : "Goes to the next page")

                    if page < pages.count - 1 {
                        Button("Skip") { finish() }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func advance() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        if page < pages.count - 1 {
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.notify(.success, enabled: settings.hapticsEnabled)
        withAnimation(reduceMotion ? nil : .easeInOut) { hasOnboarded = true }
    }
}

private struct OnboardPage {
    let symbol: String
    let title: String
    let message: String
}

private struct OnboardPageView: View {
    let page: OnboardPage

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 140, height: 140)
                Image(systemName: page.symbol)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text(page.title)
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 30)
            }
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
