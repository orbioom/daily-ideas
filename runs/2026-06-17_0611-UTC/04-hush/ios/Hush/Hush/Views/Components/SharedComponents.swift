import SwiftUI

/// A calm, reusable empty-state panel.
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(HushTheme.teal)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
                .foregroundStyle(HushTheme.primaryText(scheme))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(HushSecondaryButtonStyle())
                    .padding(.top, 4)
                    .frame(maxWidth: 240)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A Pro lock badge / nudge row used inline on gated controls.
struct ProBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(5)
            .background(Circle().fill(HushTheme.amber))
            .accessibilityLabel("Pro feature")
    }
}

/// A labelled volume slider with accessible value, gated tint.
struct VolumeSlider: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    @Binding var value: Double
    var tint: Color = HushTheme.teal
    var onEditingChanged: ((Bool) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .accessibilityHidden(true)
            Slider(value: $value, in: 0...1) { editing in
                onEditingChanged?(editing)
            }
            .tint(tint)
            Image(systemName: "speaker.wave.3.fill")
                .font(.caption)
                .foregroundStyle(HushTheme.secondaryText(scheme))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) volume")
        .accessibilityValue(Formatting.percent(value))
        .accessibilityAdjustableAction { direction in
            let step = 0.05
            switch direction {
            case .increment: value = min(1, value + step)
            case .decrement: value = max(0, value - step)
            @unknown default: break
            }
        }
    }
}
