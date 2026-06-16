import SwiftUI

/// Large, calm, accessible primary action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var filled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.rounded(17, .semibold))
                }
                Text(title)
                    .font(Theme.rounded(17, .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(filled ? Color.white : Theme.accent)
            .background(
                RoundedRectangle(cornerRadius: Theme.rButton, style: .continuous)
                    .fill(filled ? AnyShapeStyle(Theme.heroGradient) : AnyShapeStyle(Theme.accentSoft))
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

/// A reassuring disclaimer banner ("uncalibrated screening, use headphones").
struct DisclaimerBanner: View {
    var compact = false
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "headphones")
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Use headphones in a quiet room. Hark is an uncalibrated screening — it tracks changes over time, not a medical diagnosis.")
                .font(Theme.rounded(compact ? 12 : 13))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(compact ? 12 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.rChip, style: .continuous)
                .fill(Theme.accentSoft)
        )
        .accessibilityElement(children: .combine)
    }
}
