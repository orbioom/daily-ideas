import SwiftUI

/// A quiet, "Liquid Glass"-inspired surface card used across the app.
struct GlassCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

/// The app's big call-to-action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var fill: Color = Theme.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
                Text(title)
                    .font(Theme.rounded(18, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(Color.white)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A compact label/value stat used in headers and the stats screen.
struct StatChip: View {
    let label: String
    let value: String
    var tint: Color = Theme.ink

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
            Text(label.uppercased())
                .font(Theme.rounded(11, .semibold))
                .foregroundStyle(Theme.inkFaint)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A reusable empty-state block.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

/// A small pill tag (e.g. "No-guess", "Pro").
struct TagPill: View {
    let text: String
    var tint: Color = Theme.accent

    var body: some View {
        Text(text)
            .font(Theme.rounded(11, .bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(tint.opacity(0.14))
            )
    }
}

/// Section header used inside scroll views.
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
