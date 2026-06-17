import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
struct OnboardingView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(icon: "house.fill",
             title: "Know your real payment",
             body: "Abode computes your full monthly payment — principal, interest, taxes, insurance, PMI, and HOA — instantly and privately on your device."),
        Page(icon: "chart.pie.fill",
             title: "See where it goes",
             body: "A clear donut and amortization schedule show every dollar over the life of the loan, plus your payoff date and total interest."),
        Page(icon: "square.stack.3d.up.fill",
             title: "Plan with confidence",
             body: "Save scenarios, model extra payments, solve affordability from your income and DTI, and compare a refinance. No ads. No accounts.")
    ]

    var body: some View {
        ZStack {
            AbodeTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: item.icon)
                                .font(.system(size: 72, weight: .semibold))
                                .foregroundStyle(AbodeTheme.accent)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.title.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AbodeTheme.primaryText(scheme))
                            Text(item.body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(AbodeTheme.secondaryText(scheme))
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(index)
                        .accessibilityElement(children: .combine)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: reduceMotion ? .never : .automatic))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Get started") {
                        if page < pages.count - 1 {
                            page += 1
                        } else {
                            hasOnboarded = true
                        }
                    }
                    .buttonStyle(AbodePrimaryButtonStyle())

                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline)
                        .foregroundStyle(AbodeTheme.secondaryText(scheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}
