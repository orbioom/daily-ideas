import SwiftUI

/// A labeled slider used across the Studio control panel.
struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1
    var systemImage: String
    var onChange: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(Theme.rounded(14, .medium))
                    .foregroundStyle(Theme.inkSoft)
                Spacer()
                Text("\(Int((value - range.lowerBound) / max(range.upperBound - range.lowerBound, 0.0001) * 100))%")
                    .font(Theme.rounded(13, .semibold).monospacedDigit())
                    .foregroundStyle(Theme.inkFaint)
            }
            Slider(value: $value, in: range) { editing in
                if !editing { onChange?() }
            }
            .tint(Theme.accent)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int((value - range.lowerBound) / max(range.upperBound - range.lowerBound, 0.0001) * 100)) percent")
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 20
            switch direction {
            case .increment: value = (value + step).clamped(to: range)
            case .decrement: value = (value - step).clamped(to: range)
            default: break
            }
            onChange?()
        }
    }
}

/// A primary call-to-action button in the brand gradient.
struct PrimaryButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.rounded(16, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .foregroundStyle(.white)
        }
    }
}

/// A secondary, outlined button.
struct SecondaryButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Theme.rounded(16, .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: Theme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radius, style: .continuous)
                        .strokeBorder(Theme.hairline, lineWidth: 1)
                )
                .foregroundStyle(Theme.ink)
        }
    }
}

/// Small lock chip shown on Pro-gated content.
struct ProLockBadge: View {
    var body: some View {
        Label("Pro", systemImage: "lock.fill")
            .font(Theme.rounded(11, .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Theme.accent.opacity(0.5), lineWidth: 1))
            .foregroundStyle(Theme.accent)
            .accessibilityLabel("Pro feature")
    }
}
