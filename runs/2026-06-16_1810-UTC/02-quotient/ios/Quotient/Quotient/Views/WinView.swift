import SwiftUI

/// The success sheet shown when a puzzle is solved.
struct WinView: View {
    let time: String
    let mistakes: Int
    let hintsUsed: Int
    let difficulty: Difficulty
    let onNewPuzzle: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 8)

            ZStack {
                Circle()
                    .fill(Theme.success.opacity(0.15))
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(Theme.success)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
            .accessibilityHidden(true)

            Text("Solved!")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.textPrimary)

            Text("\(difficulty.displayName) · \(difficulty.size)×\(difficulty.size)")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 14) {
                statTile(value: time, label: "Time", icon: "clock")
                statTile(value: "\(mistakes)", label: "Mistakes", icon: "xmark.circle")
                statTile(value: "\(hintsUsed)", label: "Hints", icon: "lightbulb")
            }
            .padding(.horizontal)

            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Button("New Puzzle", action: onNewPuzzle)
                    .buttonStyle(PrimaryButtonStyle())
                Button("Done", action: onClose)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.5)) { appeared = true }
        }
        .accessibilityElement(children: .contain)
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
