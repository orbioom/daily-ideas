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
                    Image(systemName: systemImage)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(Theme.rounded(17, .semibold))
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
            .foregroundStyle(Theme.accent)
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

/// Displays the four-letter type code as styled facet tiles.
struct TypeBadge: View {
    let code: String
    var identity: Identity? = nil
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(code.enumerated()), id: \.offset) { _, ch in
                Text(String(ch))
                    .font(Theme.rounded(size * 0.5, .bold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
            }
            if let identity {
                Text(identity.letter)
                    .font(Theme.rounded(size * 0.42, .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: size * 0.8, height: size)
                    .background(
                        RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1.5)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Type code \(code)\(identity.map { "-\($0.letter)" } ?? "")")
    }
}

/// A small Pro lock chip used to mark gated content.
struct ProLockChip: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
            Text("Pro").font(Theme.rounded(11, .bold))
        }
        .foregroundStyle(Theme.accent)
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

/// Section header used throughout report screens.
struct SectionHeader: View {
    let title: String
    var systemImage: String? = nil
    var trailing: AnyView? = nil

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
            if let trailing { trailing }
        }
    }
}
