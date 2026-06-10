import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(icon: String, title: String, body: String)] = [
        ("textformat.abc", "Guess the word",
         "You have six tries to find the hidden five-letter word. Each guess colors the tiles to guide you."),
        ("square.grid.3x3", "Read the colors",
         "Green means the right letter in the right place. Yellow means it's in the word, elsewhere. Gray means it's not in the word at all."),
        ("infinity", "Daily and unlimited",
         "Play one shared daily puzzle to keep your streak — then play as many practice words as you want. No paywall on the game."),
        ("square.and.arrow.up", "Share, the honest way",
         "Share your result as a spoiler-free grid of colored squares. No ads, no account, no tracking."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            ZStack {
                                Circle().fill(LetterState.correct.tint.opacity(0.16)).frame(width: 120, height: 120)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 44, weight: .light))
                                    .foregroundStyle(LetterState.correct.tint)
                            }
                            .accessibilityHidden(true)
                            Text(pages[i].title).font(.title.bold())
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text)
                            Text(pages[i].body).font(.body)
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text2)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 32).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Play") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                        } else { Haptics.success(); onDone() }
                    }
                    .buttonStyle(InkButtonStyle())
                    if page < pages.count - 1 {
                        Button("Skip") { onDone() }.font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }
}

#Preview { OnboardingView(onDone: {}) }
