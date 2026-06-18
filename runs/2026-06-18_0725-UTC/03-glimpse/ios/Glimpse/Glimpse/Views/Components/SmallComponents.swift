import SwiftUI

/// Mood pill with symbol + label.
struct MoodPill: View {
    let mood: Mood
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: mood.symbol)
                .font(.system(size: compact ? 11 : 13, weight: .semibold))
            if !compact {
                Text(mood.label)
                    .font(Theme.rounded(13, .semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(mood.color, in: Capsule())
        .accessibilityElement()
        .accessibilityLabel("Mood: \(mood.label)")
    }
}

/// Small mood-colored dot (calendar / inline).
struct MoodDot: View {
    let mood: Mood
    var size: CGFloat = 8
    var body: some View {
        Circle()
            .fill(mood.color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct TagChip: View {
    let tag: String
    var selected: Bool = false

    var body: some View {
        Text("#\(tag)")
            .font(Theme.rounded(13, .medium))
            .foregroundStyle(selected ? .white : Theme.ink)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(
                selected ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(Theme.surfaceAlt),
                in: RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.sectionFont)
                .foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Calm empty state with icon, line and optional CTA.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Theme.accent.opacity(0.85))
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(19, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(Theme.rounded(15, .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Filled primary CTA in the app's voice.
struct PrimaryButton: View {
    let title: String
    var symbol: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol)
                }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Card surface modifier.
struct CardBackground: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    func body(content: Content) -> some View {
        content
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func cardSurface(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(CardBackground(radius: radius))
    }
}
