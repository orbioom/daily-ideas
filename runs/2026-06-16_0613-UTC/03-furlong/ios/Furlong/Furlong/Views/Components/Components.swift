import SwiftUI

/// A standard ledger-style card surface.
struct Card<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

/// A calm, reusable empty state.
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
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

/// A labelled stat tile used on the dashboard.
struct StatTile: View {
    let title: String
    let value: String
    var symbol: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(tint)
                            .accessibilityHidden(true)
                    }
                    Text(title)
                        .font(Theme.rounded(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                }
                Text(value)
                    .font(Theme.mono(22, .bold))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

/// A small pill badge used for purpose/category tags.
struct TagPill: View {
    let text: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(Theme.rounded(12, .semibold))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .foregroundStyle(tint)
        .background(tint.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

/// A transient success toast.
struct ToastView: View {
    let text: String
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
            Text(text)
                .font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.accent, in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

/// A reusable section header.
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .textCase(.uppercase)
            .kerning(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A simple Pro lock badge / banner used to gate premium surfaces.
struct ProLockBanner: View {
    let message: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Furlong Pro")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(Theme.ink)
                    Text(message)
                        .font(Theme.rounded(13))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the Furlong Pro upgrade screen")
    }
}

/// Primary filled button used across editors.
struct PrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(title)
                    .font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(enabled ? Theme.accent : Theme.inkSoft.opacity(0.4),
                        in: RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous))
        }
        .disabled(!enabled)
    }
}
