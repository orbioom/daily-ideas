import SwiftUI

/// First-run onboarding, gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("defaultFilingStatus") private var defaultFilingStatus = FilingStatus.single.rawValue
    @AppStorage("defaultTaxYear") private var defaultTaxYear = 2025

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        OnboardPage(
            icon: "function",
            title: "Know what you'll owe",
            body: "Quarter does the real self-employment tax math — SE tax, federal brackets, and a state approximation — so you can see your estimated bill in seconds."
        ),
        OnboardPage(
            icon: "calendar.badge.clock",
            title: "Never miss a quarter",
            body: "See your four estimated-payment due dates, what each one is, and a countdown to the next — plus plain-English safe-harbor guidance."
        ),
        OnboardPage(
            icon: "square.on.square",
            title: "Plan with scenarios",
            body: "Save snapshots of your numbers and compare them side-by-side. More income? New deduction? See the delta instantly."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardPageView(page: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            disclaimerBox

            footer
        }
        .background(Theme.background)
    }

    private var disclaimerBox: some View {
        Text("Quarter is an educational estimate using published 2024–2025 federal figures and a flat state rate you enter. It is not tax advice and not a substitute for a professional or IRS guidance.")
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.m)
            .accessibilityLabel("Disclaimer. Quarter is an educational estimate, not tax advice.")
    }

    private var footer: some View {
        VStack(spacing: Theme.Spacing.m) {
            if page < pages.count - 1 {
                Button("Continue") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                }
                .buttonStyle(PrimaryButtonStyle())

                Button("Skip") { finish() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                Button("Get Started") { finish() }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.bottom, Theme.Spacing.l)
    }

    private func finish() {
        Haptics.success()
        hasOnboarded = true
    }
}

private struct OnboardPage {
    let icon: String
    let title: String
    let body: String
}

private struct OnboardPageView: View {
    let page: OnboardPage
    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 130, height: 130)
                Image(systemName: page.icon)
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.l)

            Text(page.body)
                .font(.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
