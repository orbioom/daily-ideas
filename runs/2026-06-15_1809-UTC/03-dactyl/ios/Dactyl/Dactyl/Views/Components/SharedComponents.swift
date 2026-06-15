import SwiftUI

/// A filled, accent primary action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.heroGradient)
            )
        }
        .buttonStyle(PressableScale())
    }
}

/// A subtle, bordered secondary button.
struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).accessibilityHidden(true)
                }
                Text(title).font(Theme.rounded(16, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Theme.accentDeep)
            .background(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(Theme.accentSoft)
            )
        }
        .buttonStyle(PressableScale())
    }
}

/// Gentle scale-on-press, Reduce-Motion aware.
struct PressableScale: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// A single keycap tile — the mechanical-keyboard motif used across the app.
struct Keycap: View {
    let label: String
    var size: CGFloat = 40
    var highlighted: Bool = false
    var tint: Color? = nil

    var body: some View {
        Text(label)
            .font(Theme.mono(size * 0.42, .semibold))
            .foregroundStyle(highlighted ? Color.white : Theme.ink)
            .frame(minWidth: size, minHeight: size)
            .padding(.horizontal, label.count > 1 ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .fill(highlighted ? (tint ?? Theme.accent) : Theme.keycap)
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .strokeBorder(highlighted ? .clear : Theme.keycapEdge, lineWidth: 1)
            )
            .shadow(color: Theme.keycapShadow.opacity(0.5), radius: 0, x: 0, y: 2)
            .accessibilityHidden(true)
    }
}

/// A small Pro lock chip used to mark gated content.
struct ProLockChip: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
            Text("Pro").font(Theme.rounded(11, .bold))
        }
        .foregroundStyle(Theme.accentDeep)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.accentSoft))
        .accessibilityLabel("Pro feature, locked")
    }
}

/// Generic empty-state view.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.top, 4)
                    .frame(maxWidth: 280)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Section header used throughout screens.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            Text(title)
                .font(Theme.rounded(18, .bold))
                .foregroundStyle(Theme.ink)
            Spacer()
        }
    }
}

/// A compact labelled stat used in result and session HUDs.
struct StatPill: View {
    let value: String
    let label: String
    var tint: Color = Theme.ink

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Theme.mono(22, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label)
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(Theme.inkFaint)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}
