import SwiftUI

/// The big "Ready to Assign" banner. Green at 0 (perfectly budgeted),
/// amber when money waits to be assigned, red when over-assigned.
struct ReadyToAssignHeader: View {
    let amount: Double
    let settings: AppSettings

    private enum State { case zero, positive, negative }

    private var state: State {
        if amount > 0.005 { return .positive }
        if amount < -0.005 { return .negative }
        return .zero
    }

    private var tint: Color {
        switch state {
        case .zero: return Theme.good
        case .positive: return Theme.warn
        case .negative: return Theme.bad
        }
    }

    private var caption: String {
        switch state {
        case .zero: return "Every dollar has a job"
        case .positive: return "Assign this money"
        case .negative: return "You've over-assigned"
        }
    }

    private var symbol: String {
        switch state {
        case .zero: return "checkmark.seal.fill"
        case .positive: return "arrow.down.circle.fill"
        case .negative: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .accessibilityHidden(true)
                Text("Ready to Assign")
                    .font(Theme.rounded(13, .semibold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(tint)

            Text(settings.moneyMasked(amount))
                .font(Theme.money(40, .bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(caption)
                .font(Theme.rounded(14, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ready to assign")
        .accessibilityValue("\(settings.money(amount)). \(caption).")
    }
}
