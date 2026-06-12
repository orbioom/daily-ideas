import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.colorScheme) private var colorScheme
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        (
            "suit.spade.fill",
            "Welcome to Palace",
            "Classic Klondike solitaire, the way it should feel: a quiet table, ivory cards, and nothing between you and the game. No ads. No timers you didn't ask for."
        ),
        (
            "hand.tap.fill",
            "Tap, Don't Drag",
            "Tap any face-up card and it glides to its best legal home — foundations first, then the tableau. If a card shakes, it has no move yet. Undo is always one tap away."
        ),
        (
            "chart.bar.fill",
            "Your Table, Your Record",
            "Every game is scored and saved on this device. Track win rate, streaks, and personal bests — and switch between draw-one and draw-three whenever you like."
        ),
    ]

    var body: some View {
        ZStack {
            PalaceTheme.feltBackground(.classic, scheme: colorScheme)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 20) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 56))
                                .foregroundStyle(PalaceTheme.gold)
                                .accessibilityHidden(true)
                            Text(pages[index].title)
                                .font(.largeTitle.weight(.semibold))
                                .fontDesign(.serif)
                                .multilineTextAlignment(.center)
                            Text(pages[index].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 28)
                        }
                        .foregroundStyle(.white)
                        .tag(index)
                        .padding(.bottom, 40)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    Haptics.tap()
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Deal Me In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(PalaceTheme.gold)
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
    }
}
