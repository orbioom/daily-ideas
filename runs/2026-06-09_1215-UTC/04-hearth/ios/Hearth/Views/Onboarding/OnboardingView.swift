import SwiftUI

struct OnboardingView: View {
    @AppStorage("hearth.onboarded") private var onboarded = false
    @State private var page = 0

    private struct Slide {
        let symbol: String
        let eyebrow: String
        let title: String
        let body: String
    }

    private let slides: [Slide] = [
        .init(symbol: "house", eyebrow: "Hearth",
              title: "A calmer way to keep house",
              body: "Your home is rooms; each room has a handful of recurring chores. Hearth quietly tracks them so upkeep never piles up unseen."),
        .init(symbol: "drop", eyebrow: "Living freshness",
              title: "Watch each room breathe",
              body: "Every task has a freshness score that gently fades over time. See what's overdue today and a whole-home gauge at a glance."),
        .init(symbol: "checkmark.circle", eyebrow: "One tap",
              title: "Done, and done",
              body: "Finish a chore with a single tap. Hearth resets its clock, logs the minutes, and keeps your streaks — all on-device, all yours.")
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
