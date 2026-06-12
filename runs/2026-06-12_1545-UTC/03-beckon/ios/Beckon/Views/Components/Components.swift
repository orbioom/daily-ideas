import SwiftUI

/// A small progress ring used to show a 369 phase's reps (e.g. 2 of 6).
struct PhaseRing: View {
    let phase: Phase
    let count: Int
    var size: CGFloat = 84
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var progress: Double { min(Double(count) / Double(phase.target), 1) }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().stroke(Theme.track, lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.goldGradient, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: progress)
                VStack(spacing: 0) {
                    Image(systemName: phase.symbol)
                        .font(.caption)
                        .foregroundStyle(count >= phase.target ? Theme.accent : Theme.textSecondary)
                    Text("\(count)/\(phase.target)")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                }
            }
            .frame(width: size, height: size)
            Text(phase.label).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(phase.label) practice")
        .accessibilityValue("\(count) of \(phase.target) written")
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
                .foregroundStyle(Theme.accent.opacity(0.9))
                .accessibilityHidden(true)
            Text(title).font(.title3.weight(.semibold)).foregroundStyle(Theme.textPrimary)
            Text(message).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent).tint(Theme.accent).padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity).padding(28)
    }
}

struct StatBubble: View {
    var value: String
    var label: String
    var symbol: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol).font(.title3).foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value).font(.system(.title2, design: .rounded).weight(.bold)).foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .beckonCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

struct CategoryChip: View {
    let category: IntentionCategory
    var body: some View {
        Label(category.rawValue, systemImage: category.symbol)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Color(hue: category.hue, saturation: 0.5, brightness: 0.8).opacity(0.18), in: Capsule())
            .foregroundStyle(Color(hue: category.hue, saturation: 0.6, brightness: 0.7))
    }
}
