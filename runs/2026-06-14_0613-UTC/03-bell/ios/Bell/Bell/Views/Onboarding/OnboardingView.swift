import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private struct Slide: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        Slide(symbol: "circle.hexagongrid",
              title: "Just sit.",
              body: "Bell is an unguided meditation timer. No courses, no voices — only your breath and a gentle bell."),
        Slide(symbol: "bell",
              title: "Real bells",
              body: "Choose a singing bowl, chime, or gong. Set a warmup and interval bells to mark the passage of time."),
        Slide(symbol: "water.waves",
              title: "Optional soundscapes",
              body: "Rest in brown noise, rain, ocean, or a low drone. Or sit in complete silence — it's yours."),
        Slide(symbol: "heart.circle",
              title: "One calm purchase",
              body: "Bell is free to use forever. Bell Pro is a single one-time unlock — no subscriptions, no ads, ever.")
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { idx, slide in
                        VStack(spacing: 24) {
                            Spacer()
                            Image(systemName: slide.symbol)
                                .font(.system(size: 76, weight: .ultraLight))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(slide.title)
                                .font(Theme.serif(32, .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .multilineTextAlignment(.center)
                            Text(slide.body)
                                .font(Theme.rounded(17))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 36)
                            Spacer()
                        }
                        .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    PrimaryButton(title: page == slides.count - 1 ? "Begin" : "Continue") {
                        if page == slides.count - 1 {
                            hasOnboarded = true
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                    Button("Skip") { hasOnboarded = true }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.textSecondary)
                        .opacity(page == slides.count - 1 ? 0 : 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
