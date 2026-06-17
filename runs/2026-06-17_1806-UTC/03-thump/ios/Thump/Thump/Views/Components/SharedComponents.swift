import SwiftUI

/// Filled, accent-colored primary action button.
struct PrimaryButton: View {
    let title: String
    var symbol: String? = nil
    var fill: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(Theme.rounded(17, .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(fill ? Color.white : Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .fill(fill ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.surfaceRaised))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                    .strokeBorder(fill ? Color.clear : Theme.accent.opacity(0.5), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A dark slate panel used to group controls (groovebox surface).
struct PanelCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerLarge, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

/// Calm empty state: icon + line + optional CTA.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(Theme.accent.opacity(0.7))
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
                PrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

/// Small "PRO" pill.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(Theme.rounded(11, .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.heroGradient))
            .accessibilityLabel(Text("Pro feature"))
    }
}

struct SectionHeader: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(Theme.rounded(12, .heavy))
            .tracking(1.2)
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A calm inline banner used for the "audio unavailable" error state.
struct ErrorBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "speaker.slash.fill")
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(14, .semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Theme.warn)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerMedium, style: .continuous)
                .fill(Theme.warn.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(text))
    }
}
