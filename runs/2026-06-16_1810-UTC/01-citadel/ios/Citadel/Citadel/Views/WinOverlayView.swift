import SwiftUI

/// Gentle success state shown when the board is solved. Respects Reduce Motion by
/// presenting a static banner instead of animated flourish.
struct WinOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme

    let moveCount: Int
    let elapsed: Int
    let dealNumber: Int
    let reduceMotion: Bool
    let onNewGame: () -> Void
    let onDismiss: () -> Void

    @State private var shine = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityHidden(true)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Theme.gold.opacity(0.20))
                        .frame(width: 96, height: 96)
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.gold)
                        .scaleEffect(reduceMotion ? 1 : (shine ? 1.06 : 1.0))
                }
                .accessibilityHidden(true)

                Text("You solved it")
                    .font(.system(.title, design: .serif).weight(.bold))

                Text("Deal #\(dealNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 28) {
                    summaryItem(value: formatDuration(elapsed), label: "Time")
                    summaryItem(value: "\(moveCount)", label: "Moves")
                }
                .padding(.top, 4)

                VStack(spacing: 10) {
                    Button(action: onNewGame) {
                        Text("New game")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)

                    Button("Admire the board", action: onDismiss)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("You solved deal \(dealNumber) in \(formatDuration(elapsed)) and \(moveCount) moves")
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                shine = true
            }
        }
    }

    @ViewBuilder
    private func summaryItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
