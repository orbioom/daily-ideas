import SwiftUI

/// A calm, reusable empty-state block.
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
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Theme.coral)
                .accessibilityHidden(true)
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.primaryText(scheme))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText(scheme))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(LacePrimaryButtonStyle())
                    .padding(.top, 4)
                    .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .accessibilityElement(children: .combine)
    }
}

/// A small labelled stat used on cards and the history screen.
struct StatPill: View {
    @Environment(\.colorScheme) private var scheme
    let value: String
    let label: String
    var systemImage: String? = nil
    var tint: Color = Theme.coral

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .accessibilityHidden(true)
                }
                Text(value)
                    .font(Theme.numeral(22))
                    .foregroundStyle(Theme.primaryText(scheme))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Theme.secondaryText(scheme))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

/// A row presenting a built-in/custom plan as a selectable card.
struct PlanCardRow: View {
    @Environment(\.colorScheme) private var scheme
    let plan: TrainingPlan
    let locked: Bool
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.coral.opacity(0.14))
                    .frame(width: 50, height: 50)
                Image(systemName: plan.symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.coral)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(plan.title)
                        .font(.headline)
                        .foregroundStyle(Theme.primaryText(scheme))
                    if isActive {
                        Text("Active")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.positive))
                    }
                }
                Text(plan.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if locked {
                Image(systemName: "lock.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.coral)
                    .accessibilityLabel("Pro")
            } else {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText(scheme))
                    .accessibilityHidden(true)
            }
        }
    }
}
