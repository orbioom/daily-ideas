import SwiftUI

struct OnboardingView: View {
    @AppStorage("aura.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "brain.head.profile", eyebrow: "Aura",
              title: "A calm headache diary",
              body: "Log attacks in seconds — intensity, type, triggers, symptoms, and the meds that helped. Private and entirely on-device."),
        .init(symbol: "scope", eyebrow: "Find your patterns",
              title: "See what sets them off",
              body: "Aura ranks your likely triggers by how often they show up with an attack, and quietly flags medication-overuse risk."),
        .init(symbol: "chart.xyaxis.line", eyebrow: "Ready for your clinician",
              title: "Clear trends, your story",
              body: "Track frequency, intensity, and impact over time. A clean record you can show your neurologist — not a medical device.")
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

            Button(page < slides.count - 1 ? "Continue" : "Begin") {
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
