import SwiftUI

/// The success screen shown when a session completes (or is stopped early).
struct SessionSummaryView: View {
    let summary: SessionSummary
    let onDone: () -> Void
    let onRepeat: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 130, height: 130)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 24, y: 10)
                Image(systemName: summary.finished ? "checkmark" : "hand.thumbsup.fill")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
            .opacity(appeared || reduceMotion ? 1 : 0)

            VStack(spacing: 8) {
                Text(summary.finished ? "Session complete" : "Nice work")
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                Text(summary.finished
                     ? "You finished every rep. Your pelvic floor thanks you."
                     : "Every rep counts. We saved your progress.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                summaryTile(value: "\(summary.reps)", label: "of \(summary.totalReps) reps", symbol: "repeat")
                summaryTile(value: "\(summary.minutes)", label: summary.minutes == 1 ? "minute" : "minutes", symbol: "clock")
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 10) {
                PrimaryButton(title: "Done", systemImage: "checkmark") { onDone() }
                SecondaryButton(title: "Repeat session", systemImage: "arrow.clockwise") { onRepeat() }
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .background(Theme.bg.ignoresSafeArea())
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func summaryTile(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}
