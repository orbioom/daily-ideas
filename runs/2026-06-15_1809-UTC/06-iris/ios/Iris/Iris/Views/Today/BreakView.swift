import SwiftUI

/// A calming full-screen 20-second 20-20-20 break. A focus target slowly recedes (shrinks),
/// coaching the eyes to relax on something far away. Completion logs a break and shows success.
struct BreakView: View {
    /// Called when the break completes (not when cancelled early).
    var onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: AppSettings

    private let duration: Double = 20

    @State private var start: Date = .now
    @State private var finished = false
    @State private var loggedComplete = false

    var body: some View {
        ZStack {
            Theme.restGradient(scheme).ignoresSafeArea()
            if finished {
                successView.transition(.opacity)
            } else {
                countdownView.transition(.opacity)
            }
        }
        .onAppear { start = .now }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        TimelineView(.periodic(from: start, by: reduceMotion ? 1.0 : 0.1)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(start))
            let remaining = max(0, duration - elapsed)
            let progress = min(1, elapsed / duration)
            // Receding target: shrinks from 1.0 to 0.4 over the break.
            let targetScale: CGFloat = reduceMotion ? 1.0 : CGFloat(1.0 - 0.6 * progress)

            VStack(spacing: 28) {
                Spacer()
                Text("Look ~20 feet away")
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Soften your gaze on something far across the room and let your eyes rest.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)

                Spacer()

                ZStack {
                    if reduceMotion {
                        // Still target — no shrinking, motion-free.
                        FocusDot(size: 56, glow: false)
                    } else {
                        FocusDot(size: 56 * targetScale)
                    }
                }
                .frame(height: 140)

                Text("\(Int(ceil(remaining)))")
                    .font(Theme.rounded(64, .bold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(Int(ceil(remaining))) seconds remaining")

                Spacer()

                Button("End break") { dismiss() }
                    .font(Theme.rounded(15, .medium))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.bottom, 28)
            }
            .padding(.top, 24)
            .onChange(of: remaining <= 0) { _, done in
                if done { complete() }
            }
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 116, height: 116)
                    .shadow(color: Theme.accent.opacity(0.35), radius: 20, y: 8)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
            Text("Eyes rested")
                .font(Theme.rounded(28, .bold))
                .foregroundStyle(Theme.ink)
            Text("Nicely done. Logged toward today's goal — come back in \(settings.breakIntervalMinutes) minutes.")
                .font(Theme.rounded(16))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
            Spacer()
            PrimaryButton(title: "Done", systemImage: "checkmark") { dismiss() }
                .padding(.horizontal, 36)
            Spacer().frame(height: 28)
        }
        .accessibilityElement(children: .combine)
    }

    private func complete() {
        guard !loggedComplete else { return }
        loggedComplete = true
        onComplete()
        let anim: Animation? = reduceMotion ? nil : .easeInOut(duration: 0.3)
        withAnimation(anim) { finished = true }
    }
}
