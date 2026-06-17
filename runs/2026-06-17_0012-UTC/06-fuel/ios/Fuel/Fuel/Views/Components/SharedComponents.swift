import SwiftUI

/// A small labeled stat used in grids on the dashboard & insights.
struct StatTile: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let value: String
    var systemImage: String? = nil
    var tint: Color = FuelTheme.orange

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
            }
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(FuelTheme.primaryText(scheme))
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FuelTheme.subtleSurface(scheme))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// A reusable calm empty-state with an icon, title, message and optional action.
struct EmptyStateView: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(FuelTheme.orange)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(FuelTheme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(FuelPrimaryButtonStyle())
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }
}

/// A pill that summarizes the current phase (cut/maintain/bulk) + rate.
struct PhasePill: View {
    @Environment(\.colorScheme) private var scheme
    let goal: Goal
    let ratePercent: Double

    private var tint: Color {
        switch goal {
        case .cut:      return FuelTheme.orange
        case .maintain: return FuelTheme.teal
        case .bulk:     return FuelTheme.positive
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: goal.symbol)
                .font(.caption.weight(.bold))
                .accessibilityHidden(true)
            Text(goal == .maintain ? goal.title : "\(goal.title) · \(Fmt.percent(ratePercent))/wk")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(tint))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current phase \(goal.title), rate \(Fmt.percent(ratePercent)) per week")
    }
}

/// A labeled warning banner used for safe-rate / floor warnings.
struct WarningBanner: View {
    @Environment(\.colorScheme) private var scheme
    let messages: [String]
    var tint: Color = FuelTheme.warning

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(FuelTheme.primaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.14))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Warnings: " + messages.joined(separator: ". "))
    }
}
