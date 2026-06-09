import SwiftUI

struct OnboardingView: View {
    @AppStorage("trove.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "gift", eyebrow: "Trove",
              title: "Gifting, finally organized",
              body: "Keep the people you give to, their ideas, and every occasion in one calm place — private and on your device."),
        .init(symbol: "calendar.badge.clock", eyebrow: "Never caught off guard",
              title: "See what's coming up",
              body: "Birthdays and holidays roll forward each year automatically. Countdowns and a tidy to-buy list keep you ahead."),
        .init(symbol: "chart.pie", eyebrow: "Spend with intention",
              title: "Budgets that actually help",
              body: "Set a budget per occasion, track what you've bought, and watch your spend at a glance. No family-group friction.")
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

            Button(page < slides.count - 1 ? "Continue" : "Get started") {
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
