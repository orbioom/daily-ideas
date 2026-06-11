import SwiftUI

struct DeckOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = [
        ("rectangle.stack.fill", "Supercharged Flashcards", "Deck uses the SM-2 spaced-repetition algorithm to show you cards at exactly the right moment."),
        ("brain.filled.head.profile", "Study Smarter, Not Longer", "Rate each card as Again, Hard, Good, or Easy. Deck schedules the next review based on your answer."),
        ("chart.bar.fill", "Track Your Progress", "See retention rates, due forecasts, and study streaks — all stored privately on your device.")
    ]

    var body: some View {
        ZStack {
            DeckTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        let p = pages[i]
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: p.0)
                                .font(.system(size: 80))
                                .foregroundStyle(DeckTheme.accent)
                                .accessibilityHidden(true)
                            VStack(spacing: 12) {
                                Text(p.1)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(DeckTheme.text)
                                    .multilineTextAlignment(.center)
                                Text(p.2)
                                    .font(.body)
                                    .foregroundStyle(DeckTheme.subtle)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? DeckTheme.accent : DeckTheme.subtle.opacity(0.3))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: page)
                        }
                    }
                    Button(page < pages.count - 1 ? "Next" : "Start Learning") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
                        } else {
                            isComplete = true
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DeckTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}
