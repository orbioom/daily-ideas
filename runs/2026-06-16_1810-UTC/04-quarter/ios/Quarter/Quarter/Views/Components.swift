import SwiftUI

// MARK: - Big hero number

/// The hero figure — large, monospaced tabular digits with an accessible label.
struct HeroNumber: View {
    let title: String
    let amount: Decimal
    var emphasizeColor: Color = Theme.accent
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.secondaryText)

            Text(Format.money(amount))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(emphasizeColor)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())

            if let caption {
                Text(caption)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(Format.money(amount) + (caption.map { ", " + $0 } ?? ""))
    }
}

// MARK: - Breakdown row

/// A labeled money row used in the estimate breakdown.
struct BreakdownRow: View {
    let label: String
    let amount: Decimal
    var systemImage: String? = nil
    var valueColor: Color = Theme.primaryText
    var isApprox: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            if let systemImage {
                Image(systemName: systemImage)
                    .frame(width: 22)
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .foregroundStyle(Theme.primaryText)
                if isApprox {
                    Text("approximation")
                        .font(.caption2)
                        .foregroundStyle(Theme.tertiaryText)
                }
            }
            Spacer()
            Text(Format.money(amount))
                .monospacedDigit()
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label + (isApprox ? ", approximation" : ""))
        .accessibilityValue(Format.money(amount))
    }
}

// MARK: - Stat chip (rate pills)

struct StatChip: View {
    let title: String
    let value: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.5)
                .foregroundStyle(Theme.secondaryText)
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 46))
                .foregroundStyle(Theme.accent.opacity(0.8))
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .padding(.top, Theme.Spacing.s)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Primary button style

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Pro badge

struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Theme.accent.opacity(0.15))
            .foregroundStyle(Theme.accent)
            .clipShape(Capsule())
            .accessibilityLabel("Pro feature")
    }
}

// MARK: - Labeled currency field

struct CurrencyField: View {
    let label: String
    @Binding var text: String
    var systemImage: String = "dollarsign"
    var prompt: String = "0"
    var isPercent: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: systemImage)
                .frame(width: 22)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(label)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            TextField(prompt, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 140)
                .accessibilityLabel(label)
        }
        .padding(.vertical, 4)
    }
}
