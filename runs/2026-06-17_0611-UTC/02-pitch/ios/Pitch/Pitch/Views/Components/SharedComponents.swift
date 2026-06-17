import SwiftUI

/// A calm, centered state view used for empty / error / permission states.
struct InfoStateView: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let message: String
    var tint: Color = PitchTheme.indigo
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PitchTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(PitchTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PitchPrimaryButtonStyle())
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// A small "PRO" pill used to mark gated controls.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(PitchTheme.indigo))
            .accessibilityLabel("Pro feature")
    }
}

/// A reusable labeled stepper row used for numeric configuration.
struct StepperRow: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let valueText: String
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PitchTheme.primaryText(scheme))
            Spacer()
            HStack(spacing: 14) {
                Button(action: onDecrement) {
                    Image(systemName: "minus.circle.fill").font(.title3)
                }
                .accessibilityLabel("Decrease \(title)")
                Text(valueText)
                    .font(PitchTheme.mono(17, weight: .semibold))
                    .foregroundStyle(PitchTheme.primaryText(scheme))
                    .frame(minWidth: 64)
                    .multilineTextAlignment(.center)
                Button(action: onIncrement) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .accessibilityLabel("Increase \(title)")
            }
            .foregroundStyle(PitchTheme.indigo)
        }
    }
}
