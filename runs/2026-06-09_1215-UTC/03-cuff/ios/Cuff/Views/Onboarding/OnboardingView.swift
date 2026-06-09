import SwiftUI

struct OnboardingView: View {
    @AppStorage("cuff.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "heart.fill", eyebrow: "Cuff",
              title: "Your vitals, quietly kept",
              body: "Log blood pressure, weight, glucose, and oxygen in seconds. No ads, no accounts — everything stays on this device."),
        .init(symbol: "chart.xyaxis.line", eyebrow: "See the pattern",
              title: "Stages, trends, and averages",
              body: "Every reading is classified by the AHA stages. Watch morning versus evening, your trend over weeks, and how often you're in target."),
        .init(symbol: "doc.text", eyebrow: "Ready for your clinician",
              title: "A clean report in one tap",
              body: "Export a tidy CSV or text summary to share with your doctor. Cuff is a personal log, not a medical device — your care stays a conversation.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(slides.enumerated()), id: \.offset) { idx, slide in
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: slide.symbol)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Brand.info)
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
