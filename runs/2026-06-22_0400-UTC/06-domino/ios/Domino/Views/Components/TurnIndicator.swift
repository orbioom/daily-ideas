import SwiftUI

struct TurnIndicator: View {
    let isPlayerTurn: Bool
    let isAIThinking: Bool
    let boneyardCount: Int

    var body: some View {
        HStack(spacing: 10) {
            // Turn label
            HStack(spacing: 6) {
                Circle()
                    .fill(isPlayerTurn ? DominoTheme.gold : Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .overlay {
                        if isAIThinking {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .opacity(0.0)
                                .animation(
                                    Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: isAIThinking
                                )
                        }
                    }

                Group {
                    if isAIThinking {
                        HStack(spacing: 4) {
                            Text("AI thinking")
                                .foregroundStyle(DominoTheme.ivory.opacity(0.9))
                            ThinkingDots()
                        }
                    } else if isPlayerTurn {
                        Text("Your turn")
                            .foregroundStyle(DominoTheme.gold)
                    } else {
                        Text("AI's turn")
                            .foregroundStyle(DominoTheme.ivory.opacity(0.7))
                    }
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            }

            Spacer()

            // Boneyard count
            HStack(spacing: 4) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(DominoTheme.gold.opacity(0.7))
                Text("\(boneyardCount)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(DominoTheme.gold.opacity(0.7))
            }
            .accessibilityLabel("\(boneyardCount) tiles in boneyard")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(DominoTheme.mahoganyDark.opacity(0.6))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isAIThinking ? "AI is thinking" : (isPlayerTurn ? "Your turn" : "AI's turn"))
    }
}

struct ThinkingDots: View {
    @State private var phase = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(DominoTheme.ivory.opacity(i == phase ? 1.0 : 0.3))
                    .frame(width: 4, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: phase)
            }
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TurnIndicator(isPlayerTurn: true, isAIThinking: false, boneyardCount: 8)
        TurnIndicator(isPlayerTurn: false, isAIThinking: true, boneyardCount: 3)
        TurnIndicator(isPlayerTurn: false, isAIThinking: false, boneyardCount: 0)
    }
    .padding()
    .background(DominoTheme.mahogany)
}
