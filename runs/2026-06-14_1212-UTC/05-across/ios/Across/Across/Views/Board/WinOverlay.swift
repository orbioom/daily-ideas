import SwiftUI

/// Celebration shown when the puzzle is solved. Respects Reduce Motion.
struct WinOverlay: View {
    let elapsedSeconds: Int
    let usedReveal: Bool
    let onDone: () -> Void
    let onArchive: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onDone() }

            VStack(spacing: 16) {
                Image(systemName: usedReveal ? "checkmark.seal" : "rosette")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.4)
                    .accessibilityHidden(true)

                Text(usedReveal ? "Completed" : "Solved!")
                    .font(Theme.serif(30, .bold))
                    .foregroundStyle(Theme.ink)

                Text(usedReveal
                     ? "Finished with a little help — nice work."
                     : "Clean solve in \(TimeFormat.clock(elapsedSeconds)).")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text(TimeFormat.clock(elapsedSeconds))
                        .monospacedDigit()
                }
                .font(Theme.mono(18, .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(Theme.surfaceAlt))

                VStack(spacing: 10) {
                    PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                    Button("Back to puzzles") { onArchive() }
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                .padding(.top, 4)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.surface)
            )
            .padding(28)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
            .opacity(appeared || reduceMotion ? 1 : 0)
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { appeared = true }
            }
        }
    }
}
