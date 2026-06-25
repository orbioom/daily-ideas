import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var allSettings: [SurfSettings]
    @Environment(\.modelContext) private var context
    @State private var page = 0

    private var settings: SurfSettings? { allSettings.first }

    var body: some View {
        ZStack {
            SwellTheme.navy.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingPage(
                        sfSymbol: "water.waves",
                        title: "Your Surf Log",
                        body: "Track every session — wave height, conditions, duration, and your boards — all in one beautiful private journal.",
                        tag: 0
                    )
                    OnboardingPage(
                        sfSymbol: "chart.line.uptrend.xyaxis",
                        title: "Ride Your Progress",
                        body: "See trends across months: which spots fire, which boards perform, and when the swells hit hardest.",
                        tag: 1
                    )
                    OnboardingPage(
                        sfSymbol: "surfboard.fill",
                        title: "Your Quiver",
                        body: "Log every board and spot in your quiver. Private, offline, and free from subscriptions.",
                        tag: 2
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? SwellTheme.teal : Color.white.opacity(0.3))
                            .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button(action: advance) {
                    Text(page == 2 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundStyle(SwellTheme.navy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SwellTheme.teal)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .accessibilityLabel(page == 2 ? "Get Started" : "Next page")
            }
        }
    }

    private func advance() {
        if page < 2 {
            withAnimation { page += 1 }
        } else {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        if let s = settings {
            s.showOnboarding = false
        }
        try? context.save()
    }
}

private struct OnboardingPage: View {
    let sfSymbol: String
    let title: String
    let body: String
    let tag: Int

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: sfSymbol)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(SwellTheme.teal)
                .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(body)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
            }
            Spacer()
        }
        .tag(tag)
        .padding(.horizontal, 24)
    }
}
