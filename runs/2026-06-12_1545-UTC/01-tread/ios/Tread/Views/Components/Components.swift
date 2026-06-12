import SwiftUI

/// The hero progress ring used on Today.
struct StepRing: View {
    var progress: Double          // 0...1+
    var steps: Int
    var goal: Int
    var animate: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.track, style: StrokeStyle(lineWidth: 22, lineCap: .round))
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Theme.ringGradient, style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion || !animate ? nil : .easeOut(duration: 0.8), value: progress)
            VStack(spacing: 4) {
                Text(Fmt.steps(steps))
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .monospacedDigit()
                Text("of \(Fmt.steps(goal)) steps")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                if progress >= 1 {
                    Label("Goal met", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accent)
                        .padding(.top, 2)
                }
            }
        }
        .padding(28)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steps today")
        .accessibilityValue("\(Fmt.steps(steps)) of \(Fmt.steps(goal)), \(Int(progress * 100)) percent")
    }
}

struct StatTile: View {
    var symbol: String
    var value: String
    var label: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .treadCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct EmptyStateView: View {
    var symbol: String
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

struct SectionHeader: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
