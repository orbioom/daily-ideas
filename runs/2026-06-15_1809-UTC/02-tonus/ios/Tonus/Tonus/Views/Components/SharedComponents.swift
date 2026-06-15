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

/// A calm, recoverable error surface.
struct ErrorStateView: View {
    let title: String
    let message: String
    var retryTitle: String = "Try again"
    var retry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text(title)
                .font(Theme.rounded(19, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let retry {
                SecondaryButton(title: retryTitle, systemImage: "arrow.clockwise", action: retry)
                    .frame(maxWidth: 260)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Section header used across screens.
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

/// A circular progress ring (used for weekly goal on Today).
struct ProgressRing: View {
    var progress: Double          // 0...1
    var lineWidth: CGFloat = 12
    var size: CGFloat = 120
    var tint: Color = Theme.accent
    var label: String? = nil
    var caption: String? = nil

    private var clamped: Double { min(1, max(0, progress)) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.hairline, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    AngularGradient(colors: [tint.opacity(0.7), tint], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                if let label {
                    Text(label)
                        .font(Theme.rounded(size * 0.22, .bold))
                        .foregroundStyle(Theme.ink)
                }
                if let caption {
                    Text(caption)
                        .font(Theme.rounded(size * 0.1, .medium))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// A compact statistic tile.
struct StatTile: View {
    let value: String
    let label: String
    var symbol: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }
}
