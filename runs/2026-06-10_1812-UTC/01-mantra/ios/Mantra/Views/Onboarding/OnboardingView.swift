import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var breathe = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("sun.max.fill", "A calmer kind of affirmation app",
         "No ads mid-thought, no paywall on your own words. Just a quiet space to reset your mind."),
        ("hand.draw.fill", "Swipe through today's set",
         "Each day brings a fresh, hand-written set of affirmations. Read one, breathe, and tap to affirm it."),
        ("heart.fill", "Keep what speaks to you",
         "Favorite the lines that land, write your own, and watch a gentle streak grow as you practice.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Brand.magic.opacity(0.18))
                        .frame(width: 188, height: 188)
                        .scaleEffect(breathe && !reduceMotion ? 1.08 : 0.92)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text(pages[page].title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].body)
                        .font(.body)
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityHidden(true)

                Button(page == pages.count - 1 ? "Begin" : "Continue") {
                    Haptics.tap()
                    if page == pages.count - 1 {
                        hasOnboarded = true
                    } else {
                        withAnimation(Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 28)

                if page < pages.count - 1 {
                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                }
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) { breathe = true }
        }
    }
}
