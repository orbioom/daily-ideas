import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var onboardingQuery: [PegOnboarding]
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    var body: some View {
        ZStack {
            PegTheme.backgroundGradient.ignoresSafeArea()
            TabView(selection: $page) {
                OnboardingPage(
                    icon: "suit.spade.fill",
                    title: "Welcome to Peg",
                    body: "The classic card game of Cribbage, beautifully reimagined. Score points with 15s, pairs, runs, and flushes!",
                    accent: PegTheme.goldAccent
                ).tag(0)

                OnboardingPage(
                    icon: "hand.point.up.left.fill",
                    title: "Discard to the Crib",
                    body: "Each hand, choose 2 cards to discard to the crib. When you're the dealer, the crib belongs to you!",
                    accent: PegTheme.goldAccent
                ).tag(1)

                OnboardingPage(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Peg to 121",
                    body: "Play cards to accumulate points during pegging. First to 121 wins — you can win mid-peg, so play smart!",
                    accent: PegTheme.goldAccent
                ).tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                Spacer()
                if page == 2 {
                    Button("Start Playing") {
                        let ob = onboardingQuery.first ?? { let o = PegOnboarding(); ctx.insert(o); return o }()
                        ob.completed = true
                        try? ctx.save()
                    }
                    .font(PegTheme.headlineFont)
                    .foregroundStyle(PegTheme.feltGreenDark)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(PegTheme.goldAccent)
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let body: String
    let accent: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(accent)
            Text(title)
                .font(PegTheme.titleFont)
                .foregroundStyle(.white)
            Text(body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}
