import SwiftUI

struct OnboardingView: View {
    @AppStorage("mettle.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "flame.fill", eyebrow: "Mettle",
              title: "Programs, not just habits",
              body: "Pick a challenge like 75 Hard. Every required task must be done for the day to count. No noise, no feed — just the work."),
        .init(symbol: "checklist", eyebrow: "Every day, all of it",
              title: "A day passes when all tasks do",
              body: "Check off your tasks or log toward a target. In hard mode a missed day restarts you at Day 1; soft mode just breaks the streak."),
        .init(symbol: "lock.shield", eyebrow: "Calm and private",
              title: "On your device, free at heart",
              body: "Your run is stored on-device. Watch your day grid fill in and your streak grow — quietly, no subscription to start.")
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
