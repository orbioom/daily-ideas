import SwiftUI

struct CrawlOnboardingView: View {
    @AppStorage("crawlHasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.12, blue: 0.04).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardPage(
                        symbol: "tortoise.fill",
                        color: .green,
                        title: "Crawl",
                        body: "A slick snake game that fits in your pocket. Eat apples, grow longer, don't crash."
                    ).tag(0)

                    OnboardPage(
                        symbol: "arrow.up.arrow.down.square.fill",
                        color: Color(red: 0.2, green: 0.8, blue: 0.3),
                        title: "Swipe to Move",
                        body: "Swipe in any direction to steer your snake. The snake speeds up every 5 apples — stay sharp."
                    ).tag(1)

                    OnboardPage(
                        symbol: "infinity",
                        color: .cyan,
                        title: "Two Modes",
                        body: "Classic mode: walls are deadly. Wall Wrap mode: pass through walls and emerge on the other side."
                    ).tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.green : Color.white.opacity(0.3))
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
                        .background(Color.green)
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
