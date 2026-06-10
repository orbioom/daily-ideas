import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var pulse = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("checklist", "Lists that sort themselves",
         "Type \"milk\" and Tote files it under Dairy automatically. Your list reads like your walk through the store."),
        ("book.closed.fill", "Cook, then shop",
         "Save recipes once. Add their ingredients to any list with a tap — duplicates merge so you never buy two cartons."),
        ("star.fill", "Your staples, one tap away",
         "Tote learns what you buy often and keeps it ready, so building a list takes seconds.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    Circle().fill(Brand.live.opacity(0.16))
                        .frame(width: 188, height: 188)
                        .scaleEffect(pulse && !reduceMotion ? 1.06 : 0.92)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 58, weight: .light)).foregroundStyle(Brand.text)
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
                Button(page == pages.count - 1 ? "Start shopping" : "Continue") {
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
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
