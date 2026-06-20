import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("puzzlepiece.fill", "Welcome to Piece", "Solve beautiful hand-crafted jigsaw puzzles — from quick 16-piece challenges to expert 81-piece artwork."),
        ("hand.tap.fill", "Tap to Select, Tap to Place", "Tap a piece in the tray below to pick it up. Then tap its matching slot on the board above to snap it in."),
        ("trophy.fill", "Track Your Records", "Your fastest times are saved per puzzle and difficulty. Can you beat your personal best?"),
    ]

    var body: some View {
        ZStack {
            PieceTheme.darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: pages[page].icon)
                    .font(.system(size: 72))
                    .foregroundStyle(PieceTheme.amber)
                    .padding(.bottom, 32)

                // Text
                Text(pages[page].title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                Text(pages[page].body)
                    .font(.body)
                    .foregroundStyle(PieceTheme.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == page ? PieceTheme.amber : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 28)

                // Buttons
                Group {
                    if page < pages.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PieceTheme.amber)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 32)
                    } else {
                        Button {
                            hasSeenOnboarding = true
                        } label: {
                            Text("Start Puzzling")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(PieceTheme.amber)
                                .foregroundStyle(.black)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .animation(.easeInOut, value: page)
    }
}
