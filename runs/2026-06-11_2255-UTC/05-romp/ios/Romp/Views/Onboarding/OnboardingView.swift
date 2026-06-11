import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, message: String)] = [
        ("party.popper", "The forehead game,\ndone right",
         "Hold the phone to your forehead — friends act out the word, you guess. 8 decks, 350+ cards, zero ads."),
        ("iphone.gen3.radiowaves.left.and.right", "Tilt to score",
         "Tilt the screen to the floor when you nail it, to the ceiling to pass. Buttons work too if you'd rather tap."),
        ("rectangle.stack.badge.plus", "Your jokes, your decks",
         "Build custom decks from inside jokes, family lore and office legends. That's where the screaming starts."),
    ]

    var body: some View {
        ZStack {
            Theme.accent.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Image(systemName: item.icon)
                                .font(.system(size: 64, weight: .medium))
                                .foregroundStyle(.white)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.system(.largeTitle, design: .rounded, weight: .black))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(item.message)
                                .font(.body.weight(.medium))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.92))
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.correct()
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Let's play")
                        .font(.system(.headline, design: .rounded, weight: .black))
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Finishes onboarding")
            }
        }
    }
}
