import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(symbol: "target",
                       title: "Save with intention",
                       message: "Create a goal for each thing you're saving for — an emergency fund, a trip, a new roof. Nest keeps them separate and clear."),
        OnboardingPage(symbol: "gauge.with.needle",
                       title: "Know your pace",
                       message: "Set a target and a date. Nest tells you the monthly amount you need, and whether you're on track, behind, or ahead."),
        OnboardingPage(symbol: "square.split.2x2",
                       title: "Split a windfall",
                       message: "Got a bonus or a tax refund? Spread one lump sum across your goals smartly — by need, evenly, or by priority."),
        OnboardingPage(symbol: "lock.shield",
                       title: "Private by design",
                       message: "No bank logins. No fees on your savings. Everything lives on your device.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { idx in
                        if let p = pages[safe: idx] {
                            pageView(p).tag(idx)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Get started" : "Continue") {
                        if page == pages.count - 1 {
                            hasOnboarded = true
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    Button("Skip") { hasOnboarded = true }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: OnboardingPage) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 132, height: 132)
                Image(systemName: p.symbol)
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(p.title)
                .font(Theme.serif(28, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(p.message)
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

private struct OnboardingPage {
    let symbol: String
    let title: String
    let message: String
}
