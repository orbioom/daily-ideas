import SwiftUI

struct HeartsOnboardingView: View {
    @AppStorage("heartsHasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.08, blue: 0.04).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        symbol: "suit.heart.fill",
                        color: .red,
                        title: "Hearts",
                        body: "The classic trick-taking card game. Play against 3 AI opponents and try to keep your score the lowest."
                    ).tag(0)

                    OnboardPage(
                        symbol: "hand.raised.slash.fill",
                        color: Color(red: 0.85, green: 0.1, blue: 0.2),
                        title: "Avoid Points",
                        body: "Each heart scores 1 point. The Queen of Spades scores 13. You want the lowest score when someone hits 100."
                    ).tag(1)

                    OnboardPage(
                        symbol: "moon.fill",
                        color: .yellow,
                        title: "Shoot the Moon",
                        body: "Take ALL hearts and the Queen of Spades in one round — your opponents score 26 each and you score nothing!"
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.red : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 24)

                Button {
                    if page < 2 {
                        withAnimation { page += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                } label: {
                    Text(page < 2 ? "Next" : "Deal Me In")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.85, green: 0.1, blue: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardPage: View {
    let symbol: String
    let color: Color
    let title: String
    let body: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 80))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
            Text(title)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)
            Text(body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
