import SwiftUI

/// Success overlay shown when all 8 runs are collected.
struct WinOverlay: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let score: Int
    let moves: Int
    let time: String
    let onNewGame: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            SpindleCard {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(SpindleTheme.gold)
                        .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.6))
                        .accessibilityHidden(true)
                    Text("You won!")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(SpindleTheme.primaryText(scheme))
                    HStack(spacing: 20) {
                        stat("Score", "\(score)")
                        stat("Moves", "\(moves)")
                        stat("Time", time)
                    }
                    Button("New Game", action: onNewGame)
                        .buttonStyle(SpindlePrimaryButtonStyle())
                }
                .padding(6)
            }
            .frame(maxWidth: 360)
            .padding(28)
        }
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true } }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("You won. Score \(score), \(moves) moves, time \(time).")
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(SpindleTheme.emeraldDeep)
            Text(title)
                .font(.caption)
                .foregroundStyle(SpindleTheme.secondaryText(scheme))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}
