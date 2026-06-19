import SwiftUI

struct BrickOnboardingView: View {
    @AppStorage("brickHasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        symbol: "square.grid.3x3.fill",
                        color: Color(red: 1, green: 0.6, blue: 0.1),
                        title: "Brick",
                        body: "A classic arcade block-breaker reinvented for iPhone. Smash every brick with your ball and paddle."
                    ).tag(0)

                    OnboardPage(
                        symbol: "hand.point.right.fill",
                        color: .cyan,
                        title: "Drag to Move",
                        body: "Drag anywhere on screen to slide your paddle. Catch the ball before it falls past you."
                    ).tag(1)

                    OnboardPage(
                        symbol: "sparkles",
                        color: .yellow,
                        title: "Power-Ups",
                        body: "Catch falling power-ups for a wide paddle, extra balls, laser shots, and a slowed ball. Time them well."
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color(red: 1, green: 0.6, blue: 0.1) : Color.white.opacity(0.3))
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
                    Text(page < 2 ? "Next" : "Start Playing")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(red: 1, green: 0.6, blue: 0.1))
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
