import SwiftUI

/// A calm, friendly empty state with an icon, a message, and an optional CTA.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 110, height: 110)
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(Theme.rounded(24, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)

            Text(message)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let actionTitle, let action {
                ChunkyButton(title: actionTitle, action: action)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
