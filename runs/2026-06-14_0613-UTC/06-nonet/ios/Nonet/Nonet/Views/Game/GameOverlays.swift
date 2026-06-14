import SwiftUI

/// Celebration overlay shown on a win. Saves a GameRecord (done in the VM) and reports
/// the run. Animation respects Reduce Motion.
struct WinOverlay: View {
    let time: String
    let mistakes: Int
    let hints: Int
    let difficulty: Difficulty
    let reduceMotion: Bool
    let onDone: () -> Void

    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            CardView {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Theme.success)
                        .scaleEffect(appear ? 1 : 0.6)
                        .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6), value: appear)
                    Text("Solved!")
                        .font(Theme.rounded(28, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(difficulty.title)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 0) {
                        stat("Time", time)
                        Divider().frame(height: 34).background(Theme.separator)
                        stat("Mistakes", "\(mistakes)")
                        Divider().frame(height: 34).background(Theme.separator)
                        stat("Hints", "\(hints)")
                    }
                    .padding(.vertical, 4)

                    Button("Done", action: onDone)
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.success))
                }
            }
            .padding(28)
            .frame(maxWidth: 380)
            .scaleEffect(appear ? 1 : 0.9)
            .opacity(appear ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: appear)
        }
        .onAppear { appear = true }
        .accessibilityAddTraits(.isModal)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.textPrimary)
            Text(label).font(Theme.rounded(12)).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }
}

/// Shown when the mistake limit is reached.
struct LostOverlay: View {
    let difficulty: Difficulty
    let onDone: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            CardView {
                VStack(spacing: 16) {
                    Image(systemName: "xmark.octagon.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Theme.error)
                    Text("Out of Tries")
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("You reached the mistake limit. You can turn this off in Settings.")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("Back to Home", action: onDone)
                        .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding(28)
            .frame(maxWidth: 380)
        }
        .accessibilityAddTraits(.isModal)
    }
}

/// Overlay shown while paused — hides the board to prevent peeking.
struct PausedOverlay: View {
    let onResume: () -> Void
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.accent)
                Text("Paused")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.textPrimary)
                Button("Resume", action: onResume)
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: 220)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}
