import SwiftUI

/// 3-page onboarding: rules, features, ad-free promise. Gated via `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "square.grid.3x3.fill",
             title: "Fill Every Square",
             body: "Place 1 through 9 so each row, column, and 3×3 box contains every digit exactly once. Tap a cell, then a number."),
        Page(icon: "pencil.and.outline",
             title: "Smart Tools, Real Hints",
             body: "Pencil marks, undo, conflict highlighting, and logical hints that teach the actual technique — never random reveals."),
        Page(icon: "checkmark.seal.fill",
             title: "Clean & Ad-Free, Forever",
             body: "No ads. No interruptions. A daily puzzle and unlimited Easy & Medium are free. Nonet Pro is a one-time unlock — never a subscription."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                        pageView(p)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Start Playing") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                        } else {
                            hasOnboarded = true
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    if page < pages.count - 1 {
                        Button("Skip") { hasOnboarded = true }
                            .font(Theme.rounded(15, .medium))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 140, height: 140)
                Image(systemName: p.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(p.title)
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(p.title). \(p.body)")
    }
}
