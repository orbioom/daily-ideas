import SwiftUI

// MARK: - Empty state

/// Calm, reusable empty-state panel.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 96, height: 96)
                Image(systemName: symbol)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let actionTitle, let action {
                Button(action: {
                    Haptics.tap()
                    action()
                }) {
                    Text(actionTitle)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Theme.accent, in: Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Color swatch dot

struct ColorDot: View {
    let palette: NodePalette
    var selected: Bool = false
    var diameter: CGFloat = 26

    var body: some View {
        Circle()
            .fill(palette.accent)
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle()
                    .strokeBorder(Theme.ink.opacity(selected ? 0.9 : 0), lineWidth: 2)
                    .padding(-3)
            )
    }
}

// MARK: - Pill button

struct PillButton: View {
    let title: String
    let symbol: String
    var tint: Color = Theme.accent
    var filled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(Theme.rounded(14, .semibold))
                .foregroundStyle(filled ? Color.white : tint)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule().fill(filled ? tint : tint.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section card

struct CardSection<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}

// MARK: - Pro badge

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(Theme.rounded(10, .heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.accent, in: Capsule())
            .accessibilityLabel("Pro feature")
    }
}
