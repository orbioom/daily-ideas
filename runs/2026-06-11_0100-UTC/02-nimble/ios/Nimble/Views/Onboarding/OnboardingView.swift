import SwiftUI

struct OnboardingView: View {
    @AppStorage("nimble.onboardingDone") private var done = false
    @State private var page = 0

    private let pages: [(icon: String, color: Color, title: String, body: String)] = [
        ("brain.head.profile", .cyan, "Nimble", "5 daily brain games. Takes only minutes. Builds real cognitive fitness."),
        ("clock", .orange, "Daily Training", "Complete all 5 games once a day. Your total score is tracked over time."),
        ("chart.line.uptrend.xyaxis", .green, "Adaptive Difficulty", "Games get harder as you improve. Your best is always just a little further away."),
        ("star.fill", .purple, "Track Progress", "See your scores over 30 days, your best performances, and where you can grow."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageContent(pages[i])
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: .infinity)

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    done = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Next" : "Start Training")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(pages[page].color)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
            .animation(.none, value: page)
        }
    }

    @ViewBuilder
    private func pageContent(_ p: (icon: String, color: Color, title: String, body: String)) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: p.icon)
                .font(.system(size: 80))
                .foregroundStyle(p.color)
                .accessibilityHidden(true)
            Text(p.title)
                .font(.system(size: 34, weight: .black, design: .rounded))
            Text(p.body)
                .font(.system(size: 17))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
