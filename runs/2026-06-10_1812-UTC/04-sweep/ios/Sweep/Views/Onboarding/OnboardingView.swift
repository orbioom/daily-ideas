import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var drift = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("photo.stack", "Reclaim your storage",
         "Sweep helps you clear out the clutter in your photo library — screenshots, near-duplicates, and forgotten months — a few swipes at a time."),
        ("hand.draw.fill", "Swipe to decide",
         "Swipe left to clear, right to keep. Kept photos never come back. Nothing is deleted until you say so."),
        ("lock.shield.fill", "Private by design",
         "Sweep works entirely on your device. It only remembers which photos you've kept — never the photos themselves.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(Brand.info.opacity(0.16))
                        .frame(width: 188, height: 188)
                        .scaleEffect(drift && !reduceMotion ? 1.05 : 0.93)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 56, weight: .light)).foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(pages[page].title).font(.title.weight(.bold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].body).font(.body).foregroundStyle(Brand.text2)
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
                Button(page == pages.count - 1 ? "Get started" : "Continue") {
                    Haptics.tap()
                    if page == pages.count - 1 { hasOnboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 28)
                if page < pages.count - 1 {
                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}
