import SwiftUI

struct OnboardingView: View {
    @AppStorage("coffer.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "shippingbox.fill", eyebrow: "Coffer",
              title: "Know what you own",
              body: "Catalog your home room by room — value, brand, serial, purchase date. When something is lost, stolen or burns, you have proof, not panic."),
        .init(symbol: "checkmark.shield.fill", eyebrow: "Warranties, watched",
              title: "Never miss a coverage window",
              body: "Coffer tracks every warranty and flags the ones expiring soon, so you can make a claim while it still counts."),
        .init(symbol: "lock.fill", eyebrow: "Yours, on this device",
              title: "No subscription traps",
              body: "Everything stays on your phone. Export a clean CSV or text summary for your insurer anytime. No cloud lock-in, no bait-and-switch pricing.")
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

            Button(page < slides.count - 1 ? "Continue" : "Start cataloging") {
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
