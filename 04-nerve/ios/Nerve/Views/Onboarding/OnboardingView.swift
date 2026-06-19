import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(title: String, body: String, symbol: String, color: Color)] = [
        ("Crack the Code", "A secret code of colored pegs is hidden. Your mission: figure it out in 12 guesses or fewer.", "lock.circle.fill", .purple),
        ("Read the Clues", "After each guess, black pegs mean right color + right position. White pegs mean right color, wrong position.", "circle.grid.3x3.fill", Color(red: 0.6, green: 0.3, blue: 1.0)),
        ("Daily Challenge", "A new code appears every day — the same one for everyone. Compete with yourself and track your streak.", "calendar.circle.fill", .indigo)
    ]

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.05, blue: 0.16).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 80))
                                .foregroundStyle(pages[i].color)
                                .symbolEffect(.pulse)

                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.system(size: 30, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                Text(pages[i].body)
                                    .font(.system(size: 17, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            Spacer()
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 480)

                Button(action: {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(page < pages.count - 1 ? "Next" : "Start Playing")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
