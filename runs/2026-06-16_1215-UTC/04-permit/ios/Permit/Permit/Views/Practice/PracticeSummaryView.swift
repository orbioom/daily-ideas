import SwiftUI

/// Lightweight summary shown after a practice/review session (not the full exam result).
struct PracticeSummaryView: View {
    let total: Int
    let correct: Int
    let mode: ExamMode
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings
    @State private var appeared = false

    private var percent: Int {
        guard total > 0 else { return 0 }
        return Int((Double(correct) / Double(total) * 100).rounded())
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ReadinessRing(percent: percent, size: 170, caption: "Score")
                .scaleEffect(appeared || reduceMotion ? 1 : 0.85)
                .opacity(appeared || reduceMotion ? 1 : 0)
            VStack(spacing: 6) {
                Text(headline)
                    .font(Theme.rounded(24, .bold))
                    .foregroundStyle(Theme.ink)
                Text("\(correct) of \(total) correct")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            PrimaryButton(title: "Done", systemImage: "checkmark") {
                onDone()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .onAppear {
            Haptics.success(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }

    private var headline: String {
        switch percent {
        case 90...: return "Excellent work!"
        case 70..<90: return "Nicely done"
        case 50..<70: return "Keep practicing"
        default: return "Good effort"
        }
    }
}
