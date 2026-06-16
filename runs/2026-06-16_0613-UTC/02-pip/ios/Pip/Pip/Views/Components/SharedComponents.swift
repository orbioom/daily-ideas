import SwiftUI

/// Calm empty state with icon, message, and optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Big primary action button in the app's language.
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(Theme.rounded(18, .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: Theme.rCard, style: .continuous)
                    .fill(enabled ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.inkSoft.opacity(0.4)))
            )
        }
        .disabled(!enabled)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Brief success/info toast overlay.
struct ToastView: View {
    let text: String
    var icon: String = "checkmark.circle.fill"
    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
            Text(text).font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(Theme.accentDeep, in: Capsule())
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .accessibilityElement()
        .accessibilityLabel(text)
    }
}

/// A small stat pill for headers.
struct StatPill: View {
    let label: String
    let value: String
    var tint: Color = Theme.accent
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card()
    }
}

/// Locked-feature badge linking to the paywall.
struct ProLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
            Text("Pro")
        }
        .font(Theme.rounded(11, .bold))
        .foregroundStyle(Theme.gold)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Theme.gold.opacity(0.16), in: Capsule())
        .accessibilityLabel("Pro feature")
    }
}
