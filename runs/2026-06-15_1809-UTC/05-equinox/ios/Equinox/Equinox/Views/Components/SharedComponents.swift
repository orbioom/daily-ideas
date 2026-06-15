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

/// A subtle, accent-tinted secondary button.
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

/// Section header used throughout report screens.
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
                .font(Theme.serif(20, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }
}

/// A small botanical sprig accent — decorative, reduce-motion neutral.
struct BotanicalSprig: View {
    var size: CGFloat = 22
    var color: Color = Theme.accent
    var body: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: size, weight: .light))
            .foregroundStyle(color.opacity(0.55))
            .rotationEffect(.degrees(-18))
            .accessibilityHidden(true)
    }
}

/// A compact stat tile used on Today / Insights.
struct StatTile: View {
    let value: String
    let label: String
    var systemImage: String? = nil
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
            }
            Text(value)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A 1–5 segmented rating selector (mood / sleep / energy).
struct RatingSelector: View {
    let title: String
    let symbol: String
    @Binding var value: Int
    /// Optional labels for the lowest and highest ends.
    var lowLabel: String = "Low"
    var highLabel: String = "High"
    var hapticsEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(title)
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { n in
                    Button {
                        value = n
                        Haptics.selection(enabled: hapticsEnabled)
                    } label: {
                        Text("\(n)")
                            .font(Theme.rounded(17, .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundStyle(n == value ? .white : Theme.inkSoft)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                                    .fill(n == value ? Theme.accent : Theme.surfaceAlt)
                            )
                    }
                    .buttonStyle(PressableScale())
                    .accessibilityLabel("\(title) \(n) of 5")
                    .accessibilityAddTraits(n == value ? .isSelected : [])
                }
            }
            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkFaint)
            .accessibilityHidden(true)
        }
    }
}
