import SwiftUI

/// Rounded card surface used across the app.
struct GlintCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            )
    }
}

/// Prominent gradient action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Theme.rounded(18, .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Theme.heroGradient)
            .clipShape(RoundedRectangle(cornerRadius: Theme.rMed, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Small labeled pill (HUD stat).
struct StatPill: View {
    let icon: String
    let label: String
    let value: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                Text(value)
                    .font(Theme.rounded(18, .bold))
                    .contentTransition(.numericText())
            }
            .foregroundStyle(tint)
            Text(label)
                .font(Theme.rounded(11, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.rSmall, style: .continuous)
                .fill(Theme.surface)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// Row of 1–3 stars.
struct StarRow: View {
    let stars: Int
    var size: CGFloat = 16
    var total: Int = 3

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(i < stars ? Theme.gold : Theme.inkSoft.opacity(0.4))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(stars) of \(total) stars")
    }
}

/// Calm empty-state view with icon, message, and optional CTA.
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
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            if let ctaTitle, let action {
                Button(action: action) {
                    Text(ctaTitle)
                        .font(Theme.rounded(16, .semibold))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 11)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Lightweight transient toast.
struct Toast: View {
    let text: String
    let systemImage: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text).font(Theme.rounded(15, .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(Theme.accent))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
}

/// Standard screen background.
struct ScreenBackground: View {
    var body: some View {
        Theme.bg.ignoresSafeArea()
    }
}
