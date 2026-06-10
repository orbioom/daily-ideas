import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var glow = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("sun.and.horizon.fill", "Five quiet minutes, twice a day",
         "Plenty is a structured gratitude practice: a short morning ritual to set the tone, and an evening reflection to close the day well."),
        ("list.bullet.rectangle.portrait.fill", "Three things, gently",
         "Each morning, name three things you're grateful for and one intention. Each evening, three good moments and one thing to improve."),
        ("sparkles", "Re-reading is the magic",
         "The good days pile up. Reflect resurfaces past entries so you can feel how much you already have.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(Brand.warn.opacity(0.16))
                        .frame(width: 188, height: 188)
                        .scaleEffect(glow && !reduceMotion ? 1.06 : 0.92)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(pages[page].title)
                        .font(.title.weight(.bold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].body)
                        .font(.body).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityHidden(true)

                Button(page == pages.count - 1 ? "Start practicing" : "Continue") {
                    Haptics.tap()
                    if page == pages.count - 1 { hasOnboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 28)

                if page < pages.count - 1 {
                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}
