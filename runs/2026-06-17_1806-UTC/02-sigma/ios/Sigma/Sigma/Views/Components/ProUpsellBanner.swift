import SwiftUI

/// A compact, reusable upsell banner pointing users to the paywall.
struct ProUpsellBanner: View {
    let icon: String
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(subtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            Button("Pro", action: onTap)
                .font(Theme.rounded(13, .bold))
                .foregroundStyle(Theme.accentInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.accent))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the Pro upgrade screen")
    }
}
