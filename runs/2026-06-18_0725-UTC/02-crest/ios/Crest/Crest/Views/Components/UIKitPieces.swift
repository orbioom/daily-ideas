import SwiftUI

/// A primary filled capsule button in the Crest design language.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(fill ? Color.white : Theme.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                    .fill(fill ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surface))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                    .strokeBorder(fill ? Color.clear : Theme.accent.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableStyle())
    }
}

/// A subtle scale-on-press style that respects Reduce Motion.
struct PressableStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A rounded card surface used to group content.
struct SurfaceCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusTile, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

/// A small labelled stat chip.
struct StatPill: View {
    let label: String
    let value: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Theme.radiusButton, style: .continuous)
                .fill(Theme.surfaceSoft)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

/// Empty state with icon, message and optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var ctaTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Theme.accent.opacity(0.7))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let ctaTitle, let action {
                Button(action: action) {
                    Text(ctaTitle)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.accent)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

/// A Pro lock badge.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(Theme.rounded(10, .bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.gold))
            .accessibilityLabel("Pro feature")
    }
}

/// A transient success / info toast overlay.
struct ToastView: View {
    let icon: String
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
            Text(message)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(Theme.surface)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
        .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
    }
}
