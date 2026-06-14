import SwiftUI

/// End-of-quiz summary: score ring, accuracy, time, missed-country review list,
/// and retry / back actions.
struct ResultsView: View {
    let model: QuizViewModel
    let onRetry: () -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var scoreLine: String { "\(model.correctCount) / \(model.total)" }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                statsRow
                if model.missedCountries.isEmpty {
                    perfectCard
                } else {
                    missedSection
                }
                actions
            }
            .padding(20)
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            MasteryRing(progress: model.accuracy,
                        lineWidth: 14,
                        tint: ringTint,
                        label: "\(Int(model.accuracy * 100))%",
                        sublabel: "accuracy")
                .frame(width: 150, height: 150)
                .padding(.top, 8)
            Text(headline)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
            Text(scoreLine + " correct")
                .font(Theme.rounded(16, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(value: scoreLine, label: "Score", icon: "checkmark.circle")
            if model.timerEnabled {
                statTile(value: String(format: "%.0fs", model.elapsed), label: "Time", icon: "timer")
            }
            statTile(value: "\(Int(model.accuracy * 100))%", label: "Accuracy", icon: "target")
        }
    }

    private func statTile(value: String, label: String, icon: String) -> some View {
        GlassCard(padding: 14) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                Text(value)
                    .font(Theme.rounded(20, .bold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                Text(label)
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.inkSoft)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var perfectCard: some View {
        GlassCard {
            VStack(spacing: 10) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(model.correctCount == model.total ? "Flawless run!" : "Nicely done!")
                    .font(Theme.rounded(19, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Nothing to review — keep the streak going.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var missedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Review")
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            ForEach(model.missedCountries) { country in
                HStack(spacing: 12) {
                    Text(country.flag)
                        .font(.system(size: 28))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(country.name)
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("\(country.capital) · \(country.continent.title)")
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(country.name), capital \(country.capital), \(country.continent.title)")
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: "Play again", systemImage: "arrow.clockwise") {
                Haptics.tap(); onRetry()
            }
            Button("Back to home") { onClose() }
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.top, 4)
    }

    private var headline: String {
        switch model.accuracy {
        case 1.0: return "Perfect!"
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good work"
        case 0.4..<0.6: return "Keep going"
        default: return "Practice pays off"
        }
    }

    private var ringTint: Color {
        switch model.accuracy {
        case 0.7...: return Theme.good
        case 0.4..<0.7: return Theme.accent
        default: return Theme.bad
        }
    }
}
