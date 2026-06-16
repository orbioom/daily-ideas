import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        .init(icon: "dice.fill",
              title: "Welcome to Pip",
              body: "A clean, fair, ad-free dice game. Roll five dice, chase the best score across 13 categories, and go for the Yahtzee."),
        .init(icon: "person.2.fill",
              title: "Play your way",
              body: "Solo against your best, pass-and-play around the table, or take on CPU opponents across three difficulties."),
        .init(icon: "calendar",
              title: "A new Daily, every day",
              body: "Everyone gets the same dice sequence each day. One run, one high score. Climb your own streak."),
        .init(icon: "chart.bar.xaxis",
              title: "See yourself improve",
              body: "Track best and average scores, win-rate vs CPU, category averages and your score distribution.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, p in
                        OnboardingPage(icon: p.icon, title: p.title, body: p.body)
                            .tag(index)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Start playing" : "Next",
                                  icon: page == pages.count - 1 ? "play.fill" : nil) {
                        if page == pages.count - 1 {
                            finish()
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                        .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
    }

    private func finish() {
        withAnimation { hasOnboarded = true }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 150, height: 150)
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
