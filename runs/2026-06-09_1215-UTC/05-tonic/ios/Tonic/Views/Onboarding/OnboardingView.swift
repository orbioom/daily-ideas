import SwiftUI

struct OnboardingView: View {
    @AppStorage("tonic.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "ear", eyebrow: "Tonic",
              title: "Train your ear, calmly",
              body: "Hear an interval, chord, or scale and name it. Tones are synthesized on-device — nothing to download, no clutter, just listening."),
        .init(symbol: "slider.horizontal.3", eyebrow: "Drills that fit you",
              title: "Practice what you choose",
              body: "Pick the intervals or chords you're working on, set the direction and root, and go. Adaptive practice quietly revisits your weak spots."),
        .init(symbol: "chart.xyaxis.line", eyebrow: "See it click",
              title: "Watch mastery grow",
              body: "Every answer is tracked on-device. Per-item accuracy, streaks, and charts show your ear getting sharper — all free, all yours.")
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

            Button(page < slides.count - 1 ? "Continue" : "Start training") {
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
