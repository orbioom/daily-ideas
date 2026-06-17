import SwiftUI

/// First-run onboarding, gated by the persisted `hasOnboarded` flag.
/// Three calm pages introducing the value prop, then a disclaimer-aware finish.
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
        Page(icon: "banknote.fill",
             title: "Know your real paycheck",
             body: "Stub estimates your take-home pay after federal, state, and FICA taxes — plus 401(k), HSA, and premiums."),
        Page(icon: "chart.pie.fill",
             title: "See where it goes",
             body: "A clear breakdown shows every dollar: take-home, federal, state, and FICA — with your marginal and effective rates."),
        Page(icon: "rectangle.split.2x1",
             title: "Compare offers",
             body: "Weighing two jobs? Save scenarios and compare net pay side by side. Estimates only — not tax advice.")
    ]

    var body: some View {
        ZStack {
            StubTheme.appBackground(scheme).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        VStack(spacing: 22) {
                            Spacer()
                            Image(systemName: item.icon)
                                .font(.system(size: 72, weight: .semibold))
                                .foregroundStyle(StubTheme.green)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.title.weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(StubTheme.primaryText(scheme))
                            Text(item.body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(StubTheme.secondaryText(scheme))
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
                    .buttonStyle(StubPrimaryButtonStyle())

                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline)
                        .foregroundStyle(StubTheme.secondaryText(scheme))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}
