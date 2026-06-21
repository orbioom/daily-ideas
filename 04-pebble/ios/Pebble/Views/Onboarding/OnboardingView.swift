import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var onboardingQuery: [PebbleOnboarding]
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    var body: some View {
        ZStack {
            PebbleTheme.backgroundGradient.ignoresSafeArea()
            TabView(selection: $page) {
                pageView(
                    icon: "circle.grid.3x3.fill",
                    title: "Welcome to Pebble",
                    body: "The ancient strategy game of Mancala, beautifully crafted. Sow seeds, capture stones, fill your store!"
                ).tag(0)

                pageView(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Sow Your Seeds",
                    body: "Tap a pit on your side to sow its stones counter-clockwise. Landing in your store scores a point — and earns you an extra turn!"
                ).tag(1)

                pageView(
                    icon: "trophy.fill",
                    title: "Capture & Win",
                    body: "Land in an empty pit on your side to capture all opposite stones. Most stones in your store at the end wins!"
                ).tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                Spacer()
                if page == 2 {
                    Button("Start Playing") {
                        let ob: PebbleOnboarding
                        if let existing = onboardingQuery.first {
                            ob = existing
                        } else {
                            let o = PebbleOnboarding()
                            ctx.insert(o)
                            ob = o
                        }
                        ob.completed = true
                        try? ctx.save()
                    }
                    .font(PebbleTheme.headlineFont)
                    .foregroundStyle(PebbleTheme.woodBrown)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(PebbleTheme.sandGold)
                    .clipShape(Capsule())
                    .padding(.bottom, 60)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: page)
        }
    }

    private func pageView(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(PebbleTheme.sandGold)
            Text(title)
                .font(PebbleTheme.titleFont)
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
