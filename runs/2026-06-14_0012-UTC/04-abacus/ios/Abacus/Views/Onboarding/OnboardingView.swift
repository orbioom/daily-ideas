import SwiftUI

/// First-run onboarding, gated by @AppStorage("hasOnboarded").
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "house.fill",
             title: "Clear answers, no ads",
             body: "Abacus tells you exactly what a loan costs — monthly payment, total interest, and your payoff date — instantly."),
        Page(symbol: "bolt.heart.fill",
             title: "See your extra payments pay off",
             body: "Add a little extra each month and watch how many years and how much interest you save."),
        Page(symbol: "square.stack.3d.up.fill",
             title: "Compare, afford, refinance",
             body: "Save scenarios, find what you can afford on a budget, and check whether refinancing is worth it.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        pageView(p)
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                dots
                    .padding(.bottom, 24)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 132, height: 132)
                Image(systemName: p.symbol)
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
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
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.hairline)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(response: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button {
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start calculating")
                    .font(Theme.rounded(17, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Color.white)
            }
            Button("Skip") { finish() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkFaint)
                .opacity(page < pages.count - 1 ? 1 : 0)
                .disabled(page >= pages.count - 1)
        }
    }

    private func finish() {
        hasOnboarded = true
    }
}
