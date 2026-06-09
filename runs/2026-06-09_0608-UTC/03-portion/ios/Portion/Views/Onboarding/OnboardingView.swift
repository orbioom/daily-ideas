import SwiftUI

struct OnboardingView: View {
    @AppStorage("portion.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "list.bullet.rectangle", eyebrow: "Portion",
              title: "Build a recipe, get the label",
              body: "Add ingredients with real quantities and Portion computes the full nutrition from an on-device food database — no account, no paywall."),
        .init(symbol: "chart.pie", eyebrow: "Per serving, instantly",
              title: "The numbers that matter",
              body: "Calories, protein, carbs, fat and fiber — total and per serving — plus a calorie split and %Daily Value. Scale servings live to see it recompute."),
        .init(symbol: "fork.knife", eyebrow: "Yours to extend",
              title: "A catalog you control",
              body: "Search 60+ built-in foods or add your own custom ingredients. Everything is stored on this device.")
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

            Button(page < slides.count - 1 ? "Continue" : "Start cooking") {
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
