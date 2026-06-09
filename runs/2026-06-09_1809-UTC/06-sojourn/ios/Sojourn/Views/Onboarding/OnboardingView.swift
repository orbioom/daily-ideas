import SwiftUI

struct OnboardingView: View {
    @AppStorage("sojourn.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "globe.europe.africa.fill", eyebrow: "Sojourn",
              title: "The map of the world you've seen",
              body: "Mark every country you've visited, lived in, or dream of. A calm, complete passport — \(CountryData.total) countries, all on-device."),
        .init(symbol: "checkmark.seal.fill", eyebrow: "Track your progress",
              title: "How much world have you seen?",
              body: "Watch your percentage of the world climb, see which continents you've touched, and break it down region by region."),
        .init(symbol: "suitcase.fill", eyebrow: "Trips & bucket list",
              title: "Plan ahead, remember it all",
              body: "Group countries into trips with dates, keep a wishlist for what's next, and let the insights tell your travel story.")
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

            Button(page < slides.count - 1 ? "Continue" : "Start exploring") {
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
