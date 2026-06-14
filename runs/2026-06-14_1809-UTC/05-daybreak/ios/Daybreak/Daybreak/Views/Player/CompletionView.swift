import SwiftUI
import SwiftData

/// Celebratory completion screen shown when a run finishes (or is finished early).
/// Reads the freshly-updated runs to show the new streak.
struct CompletionView: View {
    let routineName: String
    let completed: Int
    let total: Int
    let seconds: Int
    let onDone: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var runs: [RoutineRun]
    @State private var appeared = false

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(completed) / Double(total))
    }

    private var didFullyComplete: Bool {
        fraction >= settings.completionThreshold.minFraction - 0.0001
    }

    private var streak: Int {
        RoutineEngine.overallStreak(runs: runs,
                                    threshold: settings.completionThreshold,
                                    calendar: settings.calendar)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.dawnGradient)
                    .frame(width: 160, height: 160)
                    .accessibilityHidden(true)
                Image(systemName: didFullyComplete ? "checkmark" : "hand.thumbsup.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundStyle(Theme.onHeader)
                    .accessibilityHidden(true)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
            .opacity(appeared || reduceMotion ? 1 : 0)

            VStack(spacing: 8) {
                Text(didFullyComplete ? "Routine complete" : "Nice progress")
                    .font(Theme.rounded(28, .bold))
                    .foregroundStyle(Theme.ink)
                Text(routineName)
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkSoft)
            }

            HStack(spacing: 14) {
                statTile("\(completed)/\(total)", "steps", "checklist")
                statTile(TimeFormat.clock(seconds), "time", "clock.fill")
                statTile("\(streak)", "day streak", "flame.fill")
            }
            .padding(.horizontal, 20)

            Spacer()

            PrimaryButton(title: "Done", systemImage: "sun.max.fill") {
                Haptics.tap(settings.hapticsEnabled)
                onDone()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .padding(.vertical, 24)
        .onAppear {
            guard !reduceMotion else { appeared = true; return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        }
    }

    private func statTile(_ value: String, _ label: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }
}
