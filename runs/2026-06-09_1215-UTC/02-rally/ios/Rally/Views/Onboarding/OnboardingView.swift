import SwiftUI

struct OnboardingView: View {
    @AppStorage("rally.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "circle.grid.cross", eyebrow: "Rally",
              title: "Score every match, live",
              body: "Pickleball or tennis, singles or doubles. Tap to score game by game — Rally tracks the points, calls the game, and keeps the tally."),
        .init(symbol: "chart.line.uptrend.xyaxis", eyebrow: "A rating you can trust",
              title: "See yourself improve",
              body: "Every completed match nudges a transparent, DUPR-style rating. Watch it climb, and check head-to-heads against rivals and partners."),
        .init(symbol: "lock.shield", eyebrow: "Private by default",
              title: "Your court, your data",
              body: "No accounts, no feed, no ads. Everything lives on this device. Just fast scoring and honest stats — all free to start.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: slide.symbol)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.magic)
                            .accessibilityHidden(true)
                        Eyebrow(text: slide.eyebrow)
                        Text(slide.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                        Text(slide.body)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page < slides.count - 1 ? "Continue" : "Start scoring") {
                if page < slides.count - 1 {
                    withAnimation(Brand.ease()) { page += 1 }
                } else {
                    Haptics.success()
                    onboarded = true
                }
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .accessibilityElement(children: .contain)
    }
}
