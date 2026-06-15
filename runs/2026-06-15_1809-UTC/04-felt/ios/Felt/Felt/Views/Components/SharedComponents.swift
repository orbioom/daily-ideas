import SwiftUI

/// A filled, felt-gradient primary action button.
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
        .foregroundStyle(Theme.gold)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Theme.goldSoft))
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
                PrimaryButton(title: actionTitle, systemImage: "plus", action: action)
                    .padding(.top, 4)
                    .frame(maxWidth: 280)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Section header used throughout the app.
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

/// A monospaced money figure, profit-green / loss-red, with optional privacy blur.
struct MoneyText: View {
    let value: Decimal
    var symbol: String
    var size: CGFloat = 17
    var weight: Font.Weight = .semibold
    var signed: Bool = false
    var colored: Bool = true
    var hidden: Bool = false

    private var tint: Color {
        guard colored else { return Theme.ink }
        if value > 0 { return Theme.good }
        if value < 0 { return Theme.bad }
        return Theme.ink
    }

    var body: some View {
        Text(hidden ? maskedString : Money.string(value, symbol: symbol, signed: signed))
            .font(Theme.mono(size, weight))
            .foregroundStyle(hidden ? Theme.inkFaint : tint)
            .accessibilityLabel(hidden ? "Amount hidden" : Money.string(value, symbol: symbol, signed: signed))
    }

    private var maskedString: String {
        "\(symbol)••••"
    }
}

/// A pill-style chip used for stat labels and filters.
struct StatChip: View {
    let label: String
    let value: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.mono(18, .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(Theme.rounded(12, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A chip motif decoration (stacked poker chips) — purely decorative.
struct ChipStack: View {
    var size: CGFloat = 24
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i == 1 ? Theme.gold : Color.white.opacity(0.9))
                    .frame(width: size, height: size)
                    .overlay(Circle().strokeBorder(Theme.feltDeep.opacity(0.4), lineWidth: 2))
                    .offset(y: CGFloat(i) * -3)
            }
        }
        .accessibilityHidden(true)
    }
}
