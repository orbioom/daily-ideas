import SwiftUI

struct OnboardingView: View {
    @AppStorage("contour.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "square.grid.2x2", eyebrow: "Contour",
              title: "See your transformation",
              body: "Capture progress photos and body measurements, then watch the trend take shape week over week. A calm, private record of your change."),
        .init(symbol: "lock.shield", eyebrow: "Yours alone",
              title: "Photos stay on this device",
              body: "Your progress photos are saved only on this iPhone — never uploaded, never in the cloud, never seen by us. No account, no sign-in."),
        .init(symbol: "chart.xyaxis.line", eyebrow: "Real trends",
              title: "Charts from day one",
              body: "Weight, waist, chest and more — smoothed trend lines, goal projection, and side-by-side photo compare. Contour is a tracker, not a medical device.")
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

            Button(page < slides.count - 1 ? "Continue" : "Start tracking") {
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
