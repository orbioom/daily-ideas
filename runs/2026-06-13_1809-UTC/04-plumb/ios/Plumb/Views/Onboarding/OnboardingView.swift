import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("chart.line.uptrend.xyaxis", "Your whole net worth, in one place",
         "Add every account — cash, investments, property, debts — and Plumb tracks what you’re really worth. No bank logins, ever."),
        ("calendar", "Watch it grow, month by month",
         "Update balances whenever you like. Plumb plots your net worth over time so you can see the trend, not just today."),
        ("chart.pie.fill", "Understand where it sits",
         "See how your wealth is allocated across cash, markets and real estate — and set a goal to work toward.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i).padding(.horizontal, 32)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 { page += 1 } else { hasOnboarded = true }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Get started")
                        .font(Theme.rounded(18, .bold)).frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28).padding(.bottom, 12)

                Button("Skip") { hasOnboarded = true }
                    .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft).padding(.bottom, 20)
            }
        }
    }

    private func pageView(_ p: (icon: String, title: String, body: String)) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: p.icon).font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent).accessibilityHidden(true)
            Text(p.title).font(Theme.serif(28, .bold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(p.body).font(Theme.rounded(17, .regular)).foregroundStyle(Theme.inkSoft).multilineTextAlignment(.center)
            Spacer(); Spacer()
        }
    }
}

#Preview { OnboardingView() }
